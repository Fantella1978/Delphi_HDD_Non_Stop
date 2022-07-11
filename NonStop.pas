unit NonStop;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  CoolTools, CoolCtrls, StdCtrls, FileCtrl, RzFilSys, ExtCtrls, Mask,
  ToolEdit, RzLaunch, RzDlgBtn, Menus,Registry, RzLabel, FileUtil, Abcbusy;

type
  TFormCD = class(TForm)
    CoolTrayIcon1: TCoolTrayIcon;
    CoolGroupBox1: TCoolGroupBox;
    CoolLabel1: TCoolLabel;
    CoolCheckRadioBox1: TCoolCheckRadioBox;
    Bevel1: TBevel;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Timer1: TTimer;
    Timer2: TTimer;
    Button1: TButton;
    Button2: TButton;
    abcBusy1: TabcBusy;
    RzDriveComboBox1: TRzDriveComboBox;
    CoolCheckRadioBox2: TCoolCheckRadioBox;
    CoolCheckRadioBox3: TCoolCheckRadioBox;
    CoolCheckRadioBox4: TCoolCheckRadioBox;
    procedure FormCreate(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FindWorkFiles(Path:string);
    procedure CoolCheckRadioBox2Click(Sender: TObject);
    procedure CoolCheckRadioBox3Click(Sender: TObject);
    procedure CoolCheckRadioBox4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormCD : TFormCD;
  LoadAtStartup : boolean;
  OptChanged : boolean;
  Drive : String[1];
  Reg:TRegistry;
  StrList:TStringList;
  Opt: String[1];
  FilesToFind:integer;


implementation

{$R *.DFM}

procedure TFormCD.FindWorkFiles(Path:string);
var
  SR:TSearchRec;
begin
  if StrList.Count >= FilesToFind then exit;
  try
    if FindFirst(Path,faAnyFile,SR) = 0
    then
      begin
        if (SR.Attr and faDirectory) = faDirectory
        then
          begin
            if (SR.Name <> '.')and(SR.Name <> '..') then FindWorkFiles(copy(Path,0,Length(Path)-3)+SR.Name+'\*.*');
          end
        else
          begin
            abcBusy1.Message1:='Найден: '+copy(SR.Name,0,40);
            Application.ProcessMessages;
            StrList.Add(copy(Path,0,Length(Path)-3)+SR.Name);
          end;
        while FindNext(SR) = 0 do
          begin
            if (SR.Attr and faDirectory) = faDirectory
            then
              begin
                if (SR.Name <> '.')and(SR.Name <> '..') then FindWorkFiles(copy(Path,0,Length(Path)-3)+SR.Name+'\*.*');
              end
            else
              begin
                abcBusy1.Message1:='Найден: '+copy(SR.Name,0,40);
                Application.ProcessMessages;
                StrList.Add(copy(Path,0,Length(Path)-3)+SR.Name);
              end;
          end;
      end;
  except
    on EInOutError do;
  end;
end;

procedure TFormCD.FormCreate(Sender: TObject);
begin
  StrList:=TStringList.Create;
  Reg:=TRegistry.Create;
  try
    Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run\',false);
    if Reg.ReadString('HDNonStop')<>''
      then LoadAtStartup:=true
      else LoadAtStartup:=false;
    if LoadAtStartup
      then CoolCheckRadioBox1.Checked:=True
      else CoolCheckRadioBox1.Checked:=False;
    Reg.RootKey:=HKEY_CURRENT_USER;
    Reg.OpenKey('Software\HDNonStop\',false);
    Drive:=Reg.ReadString('Drive');
    Opt:=Reg.ReadString('Opt');
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
  FilesToFind := 10000;
  if Opt='1' then FilesToFind := 1000;
  if Opt='2' then FilesToFind := 3000;
  if Opt='3' then FilesToFind := 15000;
  FormCD.Height:=184;
  FormCD.Width:=287;
  abcBusy1.Show;
  FindWorkFiles(Drive+':\*.*');
  abcBusy1.Hide;
  Timer1.Enabled:=True;
  Timer2.Enabled:=True;
  Randomize;
  OptChanged:=false;
end;

procedure TFormCD.N3Click(Sender: TObject);
begin
  CoolTrayIcon1.Active:=False;
  Show;
end;

procedure TFormCD.N1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormCD.FormActivate(Sender: TObject);
var st1:string[1];
    i:byte;
    YesDrive:boolean;
begin
  YesDrive:=False;
  if rzDriveComboBox1.Items.Count<>0
    then
      begin
        For i:=0 to rzDriveComboBox1.Items.Count do
          begin
            st1:=copy(rzDriveComboBox1.Items[i],1,1);
            if st1=Drive
              then
                begin
                  rzDriveComboBox1.ItemIndex:=i;
                  rzDriveComboBox1.Drive:=st1[1];
                  YesDrive:=True;
                end;
          end;
        if not YesDrive
          then
            begin
              rzDriveComboBox1.ItemIndex:=0;
              st1:=copy(rzDriveComboBox1.Items[0],1,1);
              rzDriveComboBox1.Drive:=st1[1];
            end;
      end
    else Close;
  if LoadAtStartup
    then CoolCheckRadioBox1.Checked:=True
    else CoolCheckRadioBox1.Checked:=False;
  if Opt='1' then CoolCheckRadioBox2.Checked:=true;
  if Opt='2' then CoolCheckRadioBox3.Checked:=true;
  if Opt='3' then CoolCheckRadioBox4.Checked:=true;

end;

procedure TFormCD.Timer1Timer(Sender: TObject);
var
  UsedFileName:String;
  File1:File of Char;
  fnum:longint;
  Buf:array[0..2048]of Char;
  BytesTransfered:integer;
begin
  if rzDriveComboBox1.Drive='' then exit;
  if StrList.Count <1 then exit;
  fnum:=1+random(StrList.Count-1);
  UsedFileName:=StrList[fnum];
  if FileExists(UsedFileName)
  then
    begin
      try
      AssignFile(File1,UsedFileName);
      Reset(File1);
      if GetFileSize(UsedFileName) > 2048
      then BlockRead(File1,Buf,2048,BytesTransfered)
      else BlockRead(File1,Buf,GetFileSize(UsedFileName),BytesTransfered);
      CloseFile(File1);
      Application.ProcessMessages;
      except
        on EInOutError do;
      end;
    end;
end;

procedure TFormCD.FormHide(Sender: TObject);
begin
  CoolTrayIcon1.Active:=True;
end;

procedure TFormCD.Timer2Timer(Sender: TObject);
begin
  Hide;
  Timer2.Enabled:=False;
end;

procedure TFormCD.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CoolTrayIcon1.Active:=False;
  StrList.Destroy;
end;

procedure TFormCD.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if MessageDlg('Нельзя выгружать программу из памяти. Это может привести к ПОЛОМКЕ ЖЕСТКОГО ДИСКА! Выгрузить её из памяти?',mtConfirmation,[mbYes,mbNo],0)=mrYes
    then CanClose:=True
    else CanClose:=False;
end;

procedure TFormCD.Button1Click(Sender: TObject);
begin
  if (rzDriveComboBox1.Drive <> Drive) or OptChanged
  then
    if (rzDriveComboBox1.Drive<>'')and
       (rzDriveComboBox1.Drive<>'A')and
       (rzDriveComboBox1.Drive<>'B')
    then
      begin
        abcBusy1.Show;
        Timer1.Enabled:=False;
        StrList.Clear;
        FindWorkFiles(rzDriveComboBox1.Drive+':\*.*');
        abcBusy1.Hide;
        Timer1.Enabled:=True;
        Drive:=rzDriveComboBox1.Drive;
      end;

  Reg:=TRegistry.Create;
  try
    Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run\',false);
    if CoolCheckRadioBox1.Checked
      then Reg.WriteString('HDNonStop',Application.EXEName)
      else Reg.DeleteValue('HDNonStop');
    Reg.RootKey:=HKEY_CURRENT_USER;
    Reg.OpenKey('Software\HDNonStop\',true);
    Reg.WriteString('Drive',rzDriveComboBox1.Drive);
    Reg.WriteString('Opt',Opt);
  finally
    Reg.CloseKey;
    Reg.Free;
  end;
  Hide;
end;

procedure TFormCD.Button2Click(Sender: TObject);
begin
  Hide;
end;

procedure TFormCD.CoolCheckRadioBox2Click(Sender: TObject);
begin
  Opt:='1';
  FilesToFind := 1000;
  OptChanged := true;
end;

procedure TFormCD.CoolCheckRadioBox3Click(Sender: TObject);
begin
  Opt:='2';
  FilesToFind := 3000;
  OptChanged := true;
end;

procedure TFormCD.CoolCheckRadioBox4Click(Sender: TObject);
begin
  Opt:='3';
  FilesToFind := 15000;
  OptChanged := true;
end;

end.
