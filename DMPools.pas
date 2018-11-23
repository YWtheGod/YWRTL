unit DMPools;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.SyncObjs;

type
  TPooledDM = class;
  TDataModuleClass = class of TDataModule;
  TProc = procedure of object;

  TDataModuleHelper = class helper for TDataModule
    procedure ReturnToPool;
    procedure ResetPool;
    procedure AfterGet; virtual;
    procedure BeforeReturn; virtual;
  end;

  TPooledDM = class(TComponent)
  protected
    DM : TDataModule;
    DestroyPool : boolean;
    AllocateTime : TDateTime;
  public
    procedure ReturnToPool;
    constructor Create(T : TDataModuleClass); reintroduce; virtual;
  end;

  TObjThreadList=class(TThreadList)
    destructor Destroy; override;
  end;

  TDMPoolItem = record
  private
    DestroyTime : TDateTime;
    PoolType : TDataModuleClass;
    Pool : TObjThreadList;
    function GetFromPool:TPooledDM;
    procedure Return(D : TPooledDM);
    procedure Init(T : TDataModuleClass);
    procedure Done;
  end;

  DMPool = class
  private
    class var
      Pools : array[0..1023] of TDMPoolItem;
      PoolCount : integer;
      Lock : TCriticalSection;
  public
    class var
      MaxPoolSize : integer;
    class function GetDM<T : TDataModule,constructor>:T; overload;
    class function GetDM(C : TDataModuleClass) : TDataModule; overload;
    class constructor Create;
    class destructor Destroy;
  end;

var
  PooledDM: TPooledDM;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{ TPooledDM }

constructor TPooledDM.Create(T: TDataModuleClass);
begin
  DM := T.Create(self);
end;

procedure TPooledDM.ReturnToPool;
var i : integer;
begin
  try
    DM.BeforeReturn;
  except
    Free;
    exit;
  end;
  i := 0;
  while (i<DMPool.PoolCount)and(self.ClassType <> DMPool.Pools[i].PoolType) do
    inc(i);
  if i=DMPool.PoolCount then Free else DMPool.Pools[i].Return(self);
end;

{ TObjThreadList }

destructor TObjThreadList.Destroy;
var L : TList;
    i : integer;
begin
  L := LockList;
  try
    for i := 0 to L.Count-1 do begin
      try
        TObject(L[i]).Free;
      except
      end;
    end;
  finally
    UnLockList;
  end;
  inherited;
end;

{ TDMPoolItem }

procedure TDMPoolItem.Init(T : TDataModuleClass);
begin
  PoolType := T;
  Pool := TObjThreadList.Create;
end;

procedure TDMPoolItem.Done;
begin
  Pool.Free;
end;

function TDMPoolItem.GetFromPool: TPooledDM;
var L : TList;
begin
  Result := nil;
  L := Pool.LockList;
  try
    if L.Count>0 then begin
      Result := TPooledDM(L[L.Count-1]);
      L.Delete(L.Count-1);
    end;
  finally
    Pool.UnlockList;
  end;
end;

procedure TDMPoolItem.Return(D: TPooledDM);
var L,FreeList : TList;
    CanReturn : boolean;
    i : integer;
begin
  L := Pool.LockList;
  try
    FreeList := nil;
    CanReturn := (D.AllocateTime>DestroyTime);
    if D.DestroyPool then begin
      DestroyTime := Now;
      FreeList := TList.Create;
      FreeList.Count := L.Count;
      for i := 0 to L.Count-1 do
        FreeList[i] := L[i];
      L.Clear;
    end;
    CanReturn := CanReturn and(L.Count<DMPool.MaxPoolSize);
    if CanReturn then L.Add(D);
  finally
    Pool.UnlockList;
  end;
  if FreeList<>nil then begin
    for i := 0 to FreeList.Count-1 do begin
      try
        TObject(FreeList[i]).Free;
      except
      end;
    end;
    FreeList.Free;
  end;
  if not CanReturn then begin
    try
      D.Free;
    except
    end;
  end;
end;

{ DMPool }

class constructor DMPool.Create;
begin
  Lock := TCriticalSection.Create;
  MaxPoolSize := 1000;
end;

class destructor DMPool.Destroy;
var i: integer;
begin
  for i := 0 to PoolCount-1 do Pools[i].Done;
  Lock.Free;
end;

class function DMPool.GetDM(C: TDataModuleClass): TDataModule;
var i : integer;
    R : TPooledDM;
begin
  i := 0;
  while (i<PoolCount)and(Pools[i].PoolType.ClassInfo<>C.ClassInfo) do inc(i);
  if i=PoolCount then begin
    Lock.Enter;
    try
      i := PoolCount-1;
      while (i>=0)and(Pools[i].PoolType.ClassInfo<>C.ClassInfo) do dec(i);
      if i=-1 then begin
        Pools[PoolCount].Init(C);
        i := PoolCount;
        inc(PoolCount);
      end;
    finally
      Lock.Leave;
    end;
  end;
  R := Pools[i].GetFromPool;
  if R=nil then R := TPooledDM.Create(C);
  Result := R.DM;
  Result.AfterGet;
end;

class function DMPool.GetDM<T>: T;
var i : integer;
    R : TPooledDM;
begin
  i := 0;
  while (i<PoolCount)and(Pools[i].PoolType.ClassInfo<>T.ClassInfo) do inc(i);
  if i=PoolCount then begin
    Lock.Enter;
    try
      i := PoolCount-1;
      while (i>=0)and(Pools[i].PoolType.ClassInfo<>T.ClassInfo) do dec(i);
      if i=-1 then begin
        Pools[PoolCount].Init(T);
        i := PoolCount;
        inc(PoolCount);
      end;
    finally
      Lock.Leave;
    end;
  end;
  R := Pools[i].GetFromPool;
  if R=nil then R := TPooledDM.Create(T);
  Result := T(R.DM);
  Result.AfterGet;
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
  if self.Owner is TPooledDM then begin
    TPooledDM(Owner).DestroyPool := true;
    TPooledDM(Owner).ReturnToPool;
  end;
end;

procedure TDataModuleHelper.ReturnToPool;
begin
  if self.Owner is TPooledDM then
    TPooledDM(Owner).ReturnToPool;
end;

end.
