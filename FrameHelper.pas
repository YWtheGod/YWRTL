unit FrameHelper;

interface
uses Classes;
type
  TFrameHelper = class(TComponent)
  private
    FOnDestroy: TNotifyEvent;
    FOnCreate: TNotifyEvent;
    procedure SetOnCreate(const Value: TNotifyEvent);
    procedure SetOnDestroy(const Value: TNotifyEvent);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  published
    property OnCreate : TNotifyEvent read FOnCreate write SetOnCreate;
    property OnDestroy : TNotifyEvent read FOnDestroy write SetOnDestroy;
  end;

  procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('YWTheGod', [TFrameHelper]);
end;

{ TFrameHelper }

procedure TFrameHelper.AfterConstruction;
begin
  inherited;
  if Assigned(FOnCreate) then FOnCreate(self);
end;

procedure TFrameHelper.BeforeDestruction;
begin
  inherited;
  if Assigned(FOnDestroy) then FOnDestroy(self);
end;

procedure TFrameHelper.SetOnCreate(const Value: TNotifyEvent);
begin
  FOnCreate := Value;
end;

procedure TFrameHelper.SetOnDestroy(const Value: TNotifyEvent);
begin
  FOnDestroy := Value;
end;

end.
