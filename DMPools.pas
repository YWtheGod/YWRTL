unit DMPools;

interface

uses
  System.SysUtils, System.Classes, System.Types, Generics.Collections, YWTypes;

type
  TDataModuleClass = class of TDataModule;

  TDataModuleHelper = class helper for TDataModule
    procedure ReturnToPool;
    procedure ResetPool;
    procedure AfterGet; virtual;
    procedure BeforeReturn; virtual;
  end;

  TDMHolder = class(TComponent)
  protected
    DestroyPool : Boolean;
    AllocateTime : TDateTime;
  public
    function DM : TDataModule; virtual; abstract;
    class function DMClass : TDataModuleClass; virtual; abstract;
    class function GetFromPool:TDMHolder; virtual; abstract;
    procedure ReturnToPool; virtual; abstract;
    class procedure RegisterClass; virtual;
    constructor Create; reintroduce; virtual;
  end;

  TDMHolder<T : TDataModule,constructor> = class(TDMHolder)
  private
    _DM : T;
  public
    class var Pool : TRingQueue512;
    class var DestroyTime : TDateTime;
    class function DMClass : TDataModuleClass; override;
    class function GetFromPool:TDMHolder; override;
    class procedure Return(D: TDMHolder); inline; static;
    class destructor Done;
    function DM : TDataModule; override;
    procedure ReturnToPool; override;
    constructor Create; override;
  end;
  TDMHolderClass = class of TDMHolder;

  DMPool = class
  private
    type THolderRec = record
      DC : TDataModuleClass;
      HC : TDMHolderClass;
    end;
    class var
      Pools : TList<THolderRec>;
    class procedure RegisterClass(H : TDMHolderClass); static;
  public
    class function GetDM<T : TDataModule,constructor>:T; overload;
    class function GetDM(C : TDataModuleClass) : TDataModule; overload;
    class constructor Create;
    class destructor Destroy;
  end;

implementation
uses Threading;

{%CLASSGROUP 'System.Classes.TPersistent'}

{ DMPool }

class constructor DMPool.Create;
begin
  Pools := TList<THolderRec>.Create;
end;

class destructor DMPool.Destroy;
begin
  Pools.Free;
end;

class function DMPool.GetDM(C: TDataModuleClass): TDataModule;
var L : THolderRec;
    R : TDMHolder;
begin
  Result := nil;
  for L in Pools do if L.DC=C then begin
    R := L.HC.GetFromPool;
    if R=nil then R := L.HC.Create;
    Result := R.DM;
    try
      Result.AfterGet;
    except on E: Exception do
    end;
    exit;
  end;
end;

class function DMPool.GetDM<T>: T;
var R : TDMHolder<T>;
begin
  R := TDMHolder<T>(TDMHolder<T>.GetFromPool);
  if R=nil then R := TDMHolder<T>.Create;
  Result := R._DM;
  try
    Result.AfterGet;
  except on E: Exception do
  end;
end;

class procedure DMPool.RegisterClass(H: TDMHolderClass);
var L : THolderRec;
begin
  for L in Pools do if L.HC=H then exit;
  L.DC := H.DMClass;
  L.HC := H;
  Pools.Add(L);
end;

{ TDataModuleHelper }

procedure TDataModuleHelper.AfterGet;
begin
end;

procedure TDataModuleHelper.BeforeReturn;
begin
end;

procedure TDataModuleHelper.ResetPool;
begin
  if self.Owner is TDMHolder then begin
    TDMHolder(Owner).DestroyPool := true;
    TDMHolder(Owner).ReturnToPool;
  end;
end;

procedure TDataModuleHelper.ReturnToPool;
begin
  if self.Owner is TDMHolder then
    TDMHolder(Owner).ReturnToPool;
end;

{ TDMHolder<T> }

constructor TDMHolder<T>.Create;
begin
  inherited;
  _DM := T(DMClass.Create(Self));
end;

function TDMHolder<T>.DM: TDataModule;
begin
  Result := _DM;
end;

class function TDMHolder<T>.DMClass: TDataModuleClass;
begin
  Result := T;
end;

class destructor TDMHolder<T>.Done;
var a : TDMHolder;
begin
  a := TDMHolder(Pool.Get);
  while a<>nil do begin
    a.free;
    a := TDMHolder(Pool.Get);
  end;
end;

class function TDMHolder<T>.GetFromPool: TDMHolder;
begin
  Result := TDMHolder(Pool.Get);
  while (Result<>nil)and(Result.AllocateTime<DestroyTime) do begin
    Result.Free;
    Result := TDMHolder(Pool.Get);
  end;
end;

class procedure TDMHolder<T>.Return(D: TDMHolder);
begin
  if D.DestroyPool then begin
    DestroyTime := Now;
    D.Free;
    TTask.Run(procedure begin
      var a := TDMHolder(Pool.Get);
      while (a<>nil)and(a.AllocateTime<DestroyTime) do begin
        a.Free;
        a := TDMHolder(Pool.Get);
      end;
      if (a<>nil)and(not Pool.Put(a)) then a.Free;
    end);
  end else if (D.AllocateTime<DestroyTime) or (not Pool.Put(D)) then D.Free;
end;

procedure TDMHolder<T>.ReturnToPool;
begin
  try
    _DM.BeforeReturn;
  except
    Free;
    exit;
  end;
  Return(self);
end;

{ TDMHolder }

constructor TDMHolder.Create;
begin
  inherited Create(nil);
  AllocateTime := Now;
end;

class procedure TDMHolder.RegisterClass;
begin
  DMPool.RegisterClass(self);
end;

end.
