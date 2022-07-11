program HDNonStop;

{Используются библиотеки: RXLibrary 2,75 	}
{			  Cool Controls 2,05	}

uses
  Forms,
  Windows,
  Registry,
  NonStop in 'NonStop.pas' {FormCD};

{$R *.RES}

var
 ExtendedStyle : integer;

begin
  Application.Initialize;
  ExtendedStyle:=GetWindowLong(Application.Handle, GWL_EXSTYLE);
  SetWindowLong(Application.Handle, GWL_EXSTYLE,
    ExtendedStyle or WS_EX_TOOLWINDOW AND NOT WS_EX_APPWINDOW);
  Application.CreateForm(TFormCD, FormCD);
  Application.Run;
end.
