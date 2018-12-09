unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Menus, Spin, StdCtrls, Buttons, tansiscreenpaintbox, viewtext,
  lconvencoding,inifiles, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Button1: TButton;
    FontDialog1: TFontDialog;
    Image1: TImage;
    Label2: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    OpenDialog: TOpenDialog;
    PaintBox1: TPaintBox;
    Panel1: TPanel;
    Panel3: TPanel;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    SaveDialog: TSaveDialog;
    ScrollBox1: TScrollBox;
    SpinEdit1: TSpinEdit;
    StatusBar: TStatusBar;
    Timer: TTimer;


    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure PaintBox1Click(Sender: TObject);
    procedure PaintBox1DblClick(Sender: TObject);
    procedure PaintBox1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PaintBox1MouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure PaintBox1Paint(Sender: TObject);
    procedure ScrollBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpinEdit1EditingDone(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private

  public
    PB : TAnsiPaintbox;
    Procedure LoadSettings;
    Procedure LoadDosPallete(n:string);
    Procedure ReLoadFile(fn:string);
  end;

var
  Form1: TForm1;
  OpenedFile: String;
  SettingsLoaded:boolean = false;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

  pb:=TANSIPaintbox.Create(scrollbox1.font);
  pb.font:=scrollbox1.font;
  loadsettings;
  scrollbox1.font.size:=spinedit1.value;
  paintbox1.font.size:=spinedit1.value;
  pb.font.size:=spinedit1.value;
  if fileexists(paramstr(1)) then begin
    if not pb.loadfromfile(paramstr(1)) then begin
      showmessage('Couldn not load file. Perhaps an unsupported format.');
      exit;
    end;
    statusbar.simpletext:=paramstr(1);

    Form1.Cursor := crHourGlass;
    paintbox1.cursor :=crHourGlass;
    timer.enabled:=false;
    pb.printfile;
    Form1.Cursor := crDefault;
    paintbox1.cursor :=crDefault;
    paintbox1.Width:=pb.buffer.width;
    paintbox1.height:=pb.buffer.height;
    PaintBox1Paint(sender);
    form1.width:=pb.buffer.width+30;
    openedfile:=paramstr(1);
    if form1.width>screen.width then form1.width:=screen.width-100;
    form1.height:=pb.buffer.height+panel1.height+10;
    if form1.height>screen.height then form1.height:=screen.height-100;
  end;
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
var df1,df2:longint;
  ext:string;
begin
  if opendialog.execute and fileexists(opendialog.filename) then begin
     statusbar.simpletext:=opendialog.filename;
     timer.enabled:=false;
     ext:=uppercase(extractfileext(opendialog.filename));
     case ext of
       '.ANS','.ASC','.DIZ','.NFO': Begin
         ReLoadfile(opendialog.filename);
         image1.visible:=false;
         paintbox1.visible:=true;
         paintbox1.OnPaint(sender);
         ReLoadfile(opendialog.filename);
         paintbox1.OnPaint(sender);
       end;
       '.BMP','.XPM','.PNG','.PBM',
       '.PPM','.ICO','.ICNS','.CUR',
       '.JPG','.PEG','.JPE','.FIF',
       '.TIF','.TIFF','.GIF': begin
         paintbox1.visible:=false;
         image1.visible:=true;
         image1.picture.loadfromfile(opendialog.filename);
         form1.Width:=image1.width+10;
         form1.height:=image1.height+panel1.height+statusbar.height+5;
         if form1.width>screen.width then form1.width:=screen.width-100;
         if form1.height>screen.height then form1.height:=screen.height-100;
       end;
     end;
  end;

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
var
  Png: TPortableNetworkGraphic;
begin
  //Save as PNG
  if SaveDialog.Execute then
  begin
    try
      Png := TPortableNetworkGraphic.Create;
      try
        Png.Assign(pb.buffer);
        Png.SaveToFile(SaveDialog.FileName);
      finally
        Png.Free;
      end;
    finally

    end;
  end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
var
  sc:RecSauceInfo;
  commentid:array[1..5] of char;
  l:array[1..64] of char;
  fp:file;
  i:word;
begin
  // Read SAUCE data. See document for more info about
  if opendialog.filename='' then exit;
  if not ReadSauceInfo(opendialog.filename,sc) then begin
     ShowMessage('File contains no SAUCE Data.');
     exit;
  end;

  form2.borderstyle:=bsdialog;
  form2.width:=400;
  form2.height:=200;
  with form2 do begin
    memo1.Color:=clblack;
    memo1.Font.color:=clwhite;
    memo1.lines.clear;
    memo1.lines.add('Title  : '+sc.title);
    memo1.lines.add('Author : '+sc.author);
    memo1.lines.add('Group  : '+sc.Group);
    memo1.lines.add('Date   : '+sc.date);
    memo1.readonly:=true;
  end;

  //sauce comments
  If sc.Comments>0 Then Begin
    form2.memo1.lines.add('');
    form2.memo1.lines.add('>> Comments ');
    assignfile(fp,opendialog.filename);
    reset(fp,1);
    seek(fp,filesize(fp)-128-5-(sc.comments*64));
    blockread(fp,commentid,5);
    if commentid='COMNT' then begin
      for i:=1 to sc.comments do begin
        blockread(fp,l,64);
        form2.memo1.lines.add(l);
      End;
    end;
    closefile(fp);
  End;

  form2.showmodal;
  form2.memo1.readonly:=false;
  form2.memo1.lines.clear;
  form2.memo1.Color:=cldefault;
  form2.memo1.Font.color:=cldefault;
  form2.borderstyle:=bssizeable;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
    timer.enabled:=true;
end;

procedure TForm1.MenuItem6Click(Sender: TObject);
var
  s:string;
begin
  //Load Pallete
  s:=(sender as tmenuitem).caption;
  LoadDosPallete(s);
  reloadfile(openedfile);
end;

procedure TForm1.PaintBox1Click(Sender: TObject);
begin

end;

procedure TForm1.PaintBox1DblClick(Sender: TObject);
Var
  f:text;
  s:string;
begin
  //Double click, opens the file to a document viewer. Perhaps not
  // important.
  if openedfile='' then exit;
  form2.memo1.lines.clear;
  assignfile(f,opendialog.filename);
  reset(f);
  while not eof(f) do begin
    readln(f,s);
    form2.memo1.lines.add(cp437ToUtf8(s));
  end;
  closefile(f);
  form2.BorderStyle:=bssizeable;
  viewtext.filename:=openedfile;
  form2.memo1.readonly:=false;
  form2.showmodal;
end;

procedure TForm1.PaintBox1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  // On mousewheel, cancel scrolling
  timer.enabled:=false;
end;

procedure TForm1.PaintBox1MouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  // On mousewheel, cancel scrolling
  timer.enabled:=false;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
begin
  // Redraw buffer
  paintbox1.canvas.draw(0,0,pb.buffer);
end;

procedure TForm1.ScrollBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Manage right click, on scrollbox.
  if Button = mbRight then
    if image1.visible then PopupMenu2.PopUp;
    if paintbox1.visible then popupmenu1.popup;
end;

procedure TForm1.SpinEdit1EditingDone(Sender: TObject);
begin
  pb.ClearCanvas;
  pb.ResetCanvas;
  paintbox1.Font.Size:=spinedit1.value;

  pb.font.size:=spinedit1.value;
  pb.buffer.canvas.font.size:=spinedit1.value;

  pb.loadfromfile(openedfile);
  pb.printfile;
  paintbox1.Width:=pb.buffer.width;
  paintbox1.height:=pb.buffer.height;
  PaintBox1Paint(sender);
  form1.width:=pb.buffer.width+30;
  if form1.width>screen.width then form1.width:=screen.width-100;
  form1.height:=pb.buffer.height+panel1.height+10;
  if form1.height>screen.height then form1.height:=screen.height-100;
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
  i:integer;
begin
  // Do the scrolling thing
  i:=scrollbox1.VertScrollBar.Position+2;
  scrollbox1.VertScrollBar.Position:=i;
  if i>scrollbox1.VertScrollBar.range then timer.enabled:=false;
end;



procedure TForm1.LoadSettings;
var
  sl:tstringlist;
  ini:tinifile;
  pal:string;
  i:integer;
  s:string;
  mi:tmenuitem;
begin
  if settingsloaded then exit;
  Ini:=Tinifile.create(extractfilepath(application.exename)+'settings.ini');
  spinedit1.value:=ini.readinteger('font','size',18);
  s:=ini.readstring('font','name','Classic Console');
  pb.Buffer.canvas.font.name:=s;
  pb.buffer.canvas.font.size:=spinedit1.value;
  paintbox1.font.name:=s;
  paintbox1.font.size:=spinedit1.value;
  fontdialog1.font.name:=s;
  fontdialog1.font.size:=spinedit1.value;

  timer.Interval:=ini.readinteger('main','scroll_speed',30);
  pal:=ini.readstring('main','pallete','default');
  if (uppercase(pal)='DEFAULT') then
     pb.loadxdefaultcolors else
       if (not ini.sectionexists(pal)) then pb.loadxdefaultcolors else begin
       loadDospallete(pal);
     end;

  sl:=tstringlist.create;
  ini.readsections(sl);
  for i:=0 to sl.count-1 do begin
    s:= uppercase(sl[i]);
    if (s<>'FONT') and (s<>'MAIN') then begin
      mi:=tmenuitem.Create(Popupmenu1);
      mi.Caption:=sl[i];
      mi.OnClick:=@MenuItem6Click;
      popupmenu1.Items.Add(mi);
    end;
  end;
  sl.free;
  ini.free;
  settingsloaded:=true;
end;

Procedure TForm1.LoadDosPallete (n:string);
var
  tmpdc:tdoscolors;
  ini:tinifile;
Begin
  if uppercase(n)='DEFAULT' then begin
    pb.LoadXDefaultColors;
    exit;
  end;
  ini:=tinifile.create(extractfilepath(application.exename)+'settings.ini');
  fillbyte(tmpdc,0,sizeof(tmpdc));
  tmpdc[0]:=Str2DosColor(ini.ReadString(n,'00','0'));
  tmpdc[1]:=Str2DosColor(ini.ReadString(n,'01','0'));
  tmpdc[2]:=Str2DosColor(ini.ReadString(n,'02','0'));
  tmpdc[3]:=Str2DosColor(ini.ReadString(n,'03','0'));
  tmpdc[4]:=Str2DosColor(ini.ReadString(n,'04','0'));
  tmpdc[5]:=Str2DosColor(ini.ReadString(n,'05','0'));
  tmpdc[6]:=Str2DosColor(ini.ReadString(n,'06','0'));
  tmpdc[7]:=Str2DosColor(ini.ReadString(n,'07','0'));
  tmpdc[8]:=Str2DosColor(ini.ReadString(n,'08','0'));
  tmpdc[9]:=Str2DosColor(ini.ReadString(n,'09','0'));
  tmpdc[10]:=Str2DosColor(ini.ReadString(n,'10','0'));
  tmpdc[11]:=Str2DosColor(ini.ReadString(n,'11','0'));
  tmpdc[12]:=Str2DosColor(ini.ReadString(n,'12','0'));
  tmpdc[13]:=Str2DosColor(ini.ReadString(n,'13','0'));
  tmpdc[14]:=Str2DosColor(ini.ReadString(n,'14','0'));
  tmpdc[15]:=Str2DosColor(ini.ReadString(n,'15','0'));
  ini.free;
  pb.DosColors:=tmpdc;
end;

procedure TForm1.ReLoadFile(fn: string);
begin
  if not fileexists(fn) then exit;
  pb.ClearCanvas;
  pb.loadfromfile(fn);
  statusbar.simpletext:=fn;
  Form1.Cursor := crHourGlass;
  paintbox1.cursor :=crHourGlass;
  pb.printfile;
  Form1.Cursor := crDefault;
  paintbox1.cursor :=crDefault;
  paintbox1.Width:=pb.buffer.width;
  paintbox1.height:=pb.buffer.height;
  PaintBox1Paint(scrollbox1);
  form1.width:=pb.buffer.width+30;
  openedfile:=fn;
  if form1.width>screen.width then form1.width:=screen.width-100;
  form1.height:=pb.buffer.height+panel1.height+10;
  if form1.height>screen.height then form1.height:=screen.height-100;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  ini:tinifile;
begin
  pb.destroy;
  ini:=tinifile.create(extractfilepath(application.exename)+'settings.ini');
  ini.writeinteger('font','size',spinedit1.value);
  ini.writestring('font','name',paintbox1.font.name);
  ini.free;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  viewtext.filename:=extractfilepath(application.exename)+'settings.ini';
  form2.memo1.readonly:=false;
  form2.memo1.lines.clear;
  form2.memo1.lines.loadfromfile(viewtext.filename);
  form2.borderstyle:=bssizeable;
  form2.showmodal;
  loadsettings;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  // The about button... do NOT change this... or you will be cursed...
  pb.ClearCanvas;
  pb.ResetCanvas;
  with pb do begin
    buffer.width:=80*GetCharWidth;
    buffer.height:=(10*GetCharHeight)+GetCharHeight;
    textcolor(15);
    CenterAt(2,15,#178+#177+#176+' xAnsiViewer v0.5 Beta '+#176+#177+#178);
    CenterAt(3,7, 'made by xqtr of Another Droid BBS');
    CenterAt(5,15,'andr01d.zapto.org:9999');
    centerat(7,8,'.....');
    centerat(9,7,'suggestions, bugs, info, at xqtr@gmx.com');
  end;
  paintbox1.Width:=pb.buffer.width;
  paintbox1.height:=pb.buffer.height;
  PaintBox1Paint(scrollbox1);
  form1.width:=pb.buffer.width+30;
  if form1.width>screen.width then form1.width:=screen.width-100;
  form1.height:=pb.buffer.height+panel1.height+10;
  if form1.height>screen.height then form1.height:=screen.height-100;
  image1.visible:=false;
  paintbox1.visible:=true;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  // change font... 
  if not fontdialog1.execute then exit;
  paintbox1.font:=fontdialog1.font;
  pb.Buffer.canvas.font:=fontdialog1.font;
  pb.ClearCanvas;
  pb.ResetCanvas;
  paintbox1.Font.Size:=spinedit1.value;

  pb.font.size:=spinedit1.value;
  pb.buffer.canvas.font.size:=spinedit1.value;

  pb.loadfromfile(openedfile);
  pb.printfile;
  paintbox1.Width:=pb.buffer.width;
  paintbox1.height:=pb.buffer.height;
  PaintBox1Paint(sender);
  form1.width:=pb.buffer.width+30;
  if form1.width>screen.width then form1.width:=screen.width-100;
  form1.height:=pb.buffer.height+panel1.height+10;
  if form1.height>screen.height then form1.height:=screen.height-100;
end;

end.

