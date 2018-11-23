unit YWEvents;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TEventReciever = class;
  TEventSender = class(TComponent)
  private
    { Private declarations }
  protected
    { Protected declarations }
    RecieverList : TList<TEventReciever>;
  public
    { Public declarations }
    function DataModule : TDataModule;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure AddReciever(R : TEventReciever);
    procedure RemoveReciever(R : TEventReciever);
    procedure BoardcastEvent(Sender : TObject=nil);
  published
    { Published declarations }
  end;

  TEventReciever = class(TComponent)
  private
    FEventSender: TEventSender;
    FOnCall: TNotifyEvent;
    procedure SetEventSender(const Value: TEventSender);
    procedure SetOnCall(const Value: TNotifyEvent);
  public
    destructor Destroy; override;
  published
    property EventSender : TEventSender read FEventSender write SetEventSender;
    property OnCall : TNotifyEvent read FOnCall write SetOnCall;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('YWTheGod', [TEventSender]);
  RegisterComponents('YWTheGod', [TEventReciever]);
end;

{ TEventSender }

procedure TEventSender.AddReciever(R: TEventReciever);
begin
  if assigned(R) then
    if not RecieverList.Contains(R) then
      RecieverList.Add(R);
end;

procedure TEventSender.BoardcastEvent(Sender : TObject);
var i : integer;
begin
  for i := 0 to RecieverList.Count-1 do
  try
    if assigned(RecieverList[i].OnCall) then
      RecieverList[i].OnCall(Sender);
  except on E: Exception do
  end;
end;

constructor TEventSender.Create(AOwner: TComponent);
begin
  inherited;
  RecieverList := TList<TEventReciever>.Create;
end;

function TEventSender.DataModule: TDataModule;
begin
  if self.Owner is TDataModule then
    Result := Owner as TDataModule
  else
    Result := nil;
end;

destructor TEventSender.Destroy;
var i : integer;
begin
  for i := 0 to RecieverList.Count-1 do
    try
      RecieverList[i].FEventSender := nil;
    except on E: Exception do
    end;
  RecieverList.Free;
  inherited;
end;

procedure TEventSender.RemoveReciever(R: TEventReciever);
begin
  if assigned(R) then begin
    R.FEventSender := nil;
    RecieverList.Remove(R);
  end;
end;

{ TEventReciever }

destructor TEventReciever.Destroy;
begin
  if assigned(FEventSender) then
    FEventSender.RemoveReciever(self);
  inherited;
end;

procedure TEventReciever.SetEventSender(const Value: TEventSender);
begin
  if assigned(FEventSender) then
    FEventSender.RemoveReciever(self);
  FEventSender := Value;
  if assigned(Value) then
    Value.AddReciever(self);
end;

procedure TEventReciever.SetOnCall(const Value: TNotifyEvent);
begin
  FOnCall := Value;
end;

end.
