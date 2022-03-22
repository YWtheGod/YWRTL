unit RTL_Reg;

interface
uses Classes,YWEvents,FrameHelper;

procedure Register;
implementation
procedure Register;
begin
  RegisterComponents('YWTheGod', [TFrameHelper,TEventSender,TEventReciever]);
end;

end.
