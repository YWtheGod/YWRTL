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
  protected
    procedure Loaded; override;
  public
    procedure BeforeDestruction; override;
  published
    property OnCreate : TNotifyEvent read FOnCreate write SetOnCreate;
    property OnDestroy : TNotifyEvent read FOnDestroy write SetOnDestroy;
  end;

implementation
uses Threading;

{ TFrameHelper }

procedure TFrameHelper.Loaded;
begin
  inherited;
  TTask.Run(procedure begin
    TThread.Queue(TThread.Current,procedure begin
      if Assigned(FOnCreate) and not (csDesigning in ComponentState) then
        FOnCreate(self);
    end);
  end);
end;

procedure TFrameHelper.BeforeDestruction;
begin
  if Assigned(FOnDestroy)and not (csDesigning in ComponentState) then
    FOnDestroy(self);
  inherited;
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
