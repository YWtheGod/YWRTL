program TestYWRTL;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,System.Win.Crtl;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
