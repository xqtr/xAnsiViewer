unit tansiscreenpaintbox;
{$mode delphi}
{$H+}
{$packedrecords 1}

interface

// THis is the best part... an object that works similar like a screen.
// you can use writexx commands to write to it and dislpay ansi graphics.

uses Graphics, ExtCtrls, Classes, SysUtils,lconvencoding,strutils;
Const
  MaxMsgLines = 5000;
Type
  RecSauceInfo = Record
    ID       : Array[1..5] of Char;
    Version  : Array[1..2] of Char;
    Title    : Array[1..35] of Char;
    Author   : Array[1..20] of Char;
    Group    : Array[1..20] of Char;
    Date     : Array[1..8] of Char;
    FileSize : Longint;
    DataType : Byte;
    FileType : Byte;
    TInfo1   : Word;
    TInfo2   : Word;
    TInfo3   : Word;
    TInfo4   : Word;
    Comments : Byte;
    Flags    : Byte;
    Filler   : Array[1..22] of Char;
  End;

    TDosColor = Record
      R:Byte;
      G:Byte;
      B:Byte;
    end;

    TDosColors = Array[0..15] of TDosColor ;

    RecMessageLine = Array[1..160] of Record
                         Ch   : Char;
                         Attr : Byte;
                     End;

    //AnsiImage = Array[1..MaxMsgLines] of RecMessageLine;
    AnsiImage = Array of RecMessageLine;

Const
  DefDosColors : TDosColors = (
    (R:000;   G:000;   B:000;  ), //00
    (R:000;   G:000;   B:128;  ), //01
    (R:000;   G:128;   B:000;  ), //02
    (R:000;   G:128;   B:128;  ), //03
    (R:170;   G:000;   B:000;  ), //04
    (R:128;   G:000;   B:128;  ), //05
    (R:128;   G:128;   B:000;  ), //06
    (R:192;   G:192;   B:192;  ), //07
    (R:128;   G:128;   B:128;  ), //08
    (R:000;   G:000;   B:255;  ), //09
    (R:000;   G:255;   B:000;  ), //10
    (R:000;   G:255;   B:255;  ), //11
    (R:255;   G:000;   B:000;  ), //12
    (R:255;   G:000;   B:255;  ), //13
    (R:255;   G:255;   B:000;  ), //14
    (R:255;   G:255;   B:255; )   //15
  );
Type

{ TANSIPaintbox }

TANSIPaintbox = Class
  private
    FAttr : Byte;
    FFont : TFont;
    FLine  : Integer;
    FWhereX : Integer;
    FWhereY : Integer;
    FX,FY   : Integer;
    GotAnsi  : Boolean;
    GotPipe  : Boolean;
    PipeCode : String[2];
    Data     : AnsiImage;
    Code     : String;
    Lines    : Integer;
    Escape   : Byte;
    SavedX   : Integer;
    SavedY   : Integer;
    FCharWidth : Word;
    FCharHeight : Word;

    DosPal : TDosColors;
    FWidth  : Integer;
    FHeight : Integer;
    CurY    : Integer;
    CurX    : Integer;
    CWidth  : Word;

  Protected


    Procedure   ResetControlCode;
    Function    ParseNumber (Var Line: String) : Integer;
    Function    AddChar (Ch: Char) : Boolean;
    Procedure   MoveXY (X, Y: Word);
    Procedure   MoveUP;
    Procedure   MoveDOWN;
    Procedure   MoveLEFT;
    Procedure   MoveRIGHT;
    Procedure   MoveCursor;
    Procedure   CheckCode (Ch: Char);
    Procedure   ProcessChar (Ch: Char);
    Function    ProcessBuf (Var Buf; BufLen: Word) : Boolean;
    Procedure    SetBFont(Const TF:TFont);
  public
    Buffer    : TBitmap;
    FSL       : TStringList;
    Property DosColors:TDosColors Read DosPal Write DosPal;
    Destructor Destroy;
    Function GetCharWidth:Byte;
    Function GetCharHeight:Byte;
    Constructor Create(TF:TFont);
    Property WhereX:Integer Read FWhereX;
    Property WhereY:Integer Read FWhereY;
    Procedure TextColor(FG:Byte);
    Procedure TextBackGround(FG:Byte);
    Procedure SetTextAttr(Attr:Byte);
    Procedure WriteChar(C:Char);
    Procedure WriteString(S:String);
    Procedure WriteXY(x,y,a:Byte; S:String);
    Procedure CenterAt(y,a:byte; S:String);
    Procedure WriteLn(S:String);Overload;
    Procedure WriteLn; Overload;
    Procedure GotoXY(X,Y:Integer);
    Function  LoadFromFile(FN:String):boolean;
    Procedure PrintFile;
    Procedure ResetCanvas;
    Procedure ClearCanvas;
    Procedure LoadXDefaultColors;
    Function DosColor(CL:Byte):TColor;
    Property Width:Integer Read FWidth;
    Property Height:Integer Read FHeight;
    Property Font:TFont Read FFont Write SetBFont;
    Property ConWidth:Word read CWidth;

  end;


Function ReadSauceInfo (FN: String; Var Sauce: RecSauceInfo) : Boolean;
Function Str2DosColor(Str:string):TDosColor;


implementation

{ TANSIPaintbox }

function TANSIPaintbox.DosColor(CL: Byte): TColor;
Begin
  Result:=RGBToColor(DosPal[CL].R,DosPal[CL].G,DosPal[CL].B)
End;

function ReadSauceInfo(FN: String; var Sauce: RecSauceInfo): Boolean;
Var
  DF  : TFilestream;
  Str : String;
  Res : LongInt;
Begin
  Result := False;
  if not fileexists(fn) then exit;
  fillbyte(sauce,sizeof(sauce),0);
  df := TFilestream.Create(FN, fmOpenRead);
  try
    df.seek(-128,soFromEnd);
    res:=df.Read (Sauce, sizeof(sauce));
  finally
    df.free;
  End;

  //Writeln(stripc(sauce.title));
  Result := copy(sauce.id,1,5) = 'SAUCE';
end;

function Str2DosColor(Str: string): TDosColor;
begin
  try
    result.r:=strtoint(extractdelimited(1,str,[',',';']));
    result.g:=strtoint(extractdelimited(2,str,[',',';']));
    result.b:=strtoint(extractdelimited(3,str,[',',';']));
  except
    result.r:=0;
    result.g:=0;
    result.b:=0;
  end;
end;

constructor TANSIPaintbox.Create(TF:TFont);
begin
  Buffer:=TBitmap.Create;

  Fx:=0;
  Fy:=0;
  FWhereX:=1;
  CurX:=1;
  CurY:=1;
  FWhereY:=1;
  FAttr:=7;
  Fline:=0;
  Lines:=1;
  GotAnsi  := False;
  GotPipe  := False;
  PipeCode := '';
  FFont:=TF;
  cwidth:=80;
  setlength(data,2);
  data[1,1].attr:=7;
  FillChar (Data, SizeOf(Data), 0);
//  Buffer.Width:=80*GetCharWidth;
Buffer.Width:=132*GetCharWidth;
  Buffer.Height:=100;
  FSl:=TStringList.Create;

  DosPal :=DefDosColors;

  ResetControlCode;
end;

destructor TANSIPaintbox.Destroy;
begin
  Fsl.Free;
  Buffer.Free;
end;

procedure TANSIPaintbox.TextColor(FG: Byte);
begin
  Buffer.Canvas.Font.Color:=RGBToColor(DosPal[FG].R,DosPal[FG].G,DosPal[FG].B)
end;

procedure TANSIPaintbox.TextBackGround(FG: Byte);
begin
  Buffer.Canvas.Brush.Color:=RGBToColor(DosPal[FG].R,DosPal[FG].G,DosPal[FG].B)
end;

procedure TANSIPaintbox.SetTextAttr(Attr: Byte);
begin
  FAttr := Attr;
  TextColor(Attr Mod 16);
  TextBackground(Attr div 16);
end;

procedure TANSIPaintbox.WriteChar(C: Char);
begin
  Buffer.Canvas.TextOut(Fx,Fy,cp437ToUtf8(C));
  If C<>#13 Then Begin
    gotoxy(fwherex+1,fwherey);
  end
  Else Begin
{    Fx:=0;
    Fy:=Fy+FCharHeight;
    FWhereX:=1;
    FWhereY:=FWhereY+1; }
    gotoxy(0,fwherey+1);
  end;
  //Buffer.Height:=(FWhereY*CharHeight)+30;
  //  Buffer.Height:=(Lines*CharHeight)+30;
end;

procedure TANSIPaintbox.WriteString(S: String);
Var
   i : Integer;
begin
  For i:=1 to Length(S) Do WriteChar(S[i]);
end;

procedure TANSIPaintbox.WriteXY(x, y, a: Byte; S: String);
begin
  GotoXY(x,y);
  SetTextAttr(a);
  WriteString(S);
end;

procedure TANSIPaintbox.CenterAt(y, a: byte; S: String);
begin
  writexy(40-(length(s) div 2),y,a,s);
end;

procedure TANSIPaintbox.WriteLn(S: String);
begin
  WriteString(S);
  WriteChar(#13);
end;

procedure TANSIPaintbox.WriteLn;
begin
  WriteChar(#13);
end;

procedure TANSIPaintbox.GotoXY(X, Y: Integer);
begin
  FWhereX:=X;
  FWhereY:=Y;
  Fx:=(X-1)*FCharWidth;
  Fy:=(Y-1)*FCharHeight;
end;

function TANSIPaintbox.LoadFromFile(FN: String):boolean;
Var
  Buf      : Array[1..4096] of Char;
  BufLen   : LongInt;
  TopLine  : LongInt;
  WinSize  : LongInt;
  AFile    : File;
  Ch       : Char;
  Str      : String;
  Sauce    : RecSauceInfo;
  Done     : Boolean = False;
  Per : SmallInt;
Begin
  result:=false;
  SetTextAttr(7);
  If Not FileExists(FN) Then Exit;
  FSL.Loadfromfile(fn);
  cwidth:=80;
  ReadSauceInfo(FN, Sauce);
  If Sauce.Datatype=1 then begin
    case sauce.filetype of
      0: cwidth:=sauce.tinfo1;
      1: cwidth:=sauce.tinfo1;
      2,3,4,5: begin //ansimation
               exit;
         end;
    end;
  end else if sauce.datatype>=80 then cwidth:=sauce.datatype;

  AssignFile  (AFile, FN);
  Reset (AFile, 1);
  setlength(data,2);
  While Not Eof(AFile) Do Begin
    BlockRead (AFile, Buf, SizeOf(Buf), BufLen);
    If ProcessBuf (Buf, BufLen) Then Break;
  End;

  CloseFile (AFile);
  result:=true;
//  PrintFile;
end;

procedure TANSIPaintbox.PrintFile;
Var
  A,B:integer;
Begin
  a:=1;
  FCharHeight:=GetCharHeight;
  FCharWidth:=GetCharWidth;
  buffer.width:=ConWidth*FCharWidth;
  buffer.height:=(Lines*FCharHeight)+FCharHeight;
  while a<=Lines do Begin
    GotoXY(1,a);
    For b:=1 to ConWidth do begin
      SetTextAttr(Data[a][b].Attr);
      case Data[a][b].Ch of
      #0,#255: WriteChar(' ');
      else
          WriteChar(Data[a][b].Ch);
      End;

    end;
  a:=a+1;
  End;
end;

procedure TANSIPaintbox.ResetCanvas;
begin
  Buffer.Canvas.Clear;
  setlength(data,2);
  FillChar (Data, SizeOf(Data), 0);
  FCharHeight:=GetCharHeight;
  FCharWidth:=GetCharWidth;
  Buffer.Width:=132*FCharWidth;
  Buffer.Height:=100;
end;

procedure TANSIPaintbox.ClearCanvas;
begin
  Buffer.Canvas.Clear;
  Fx:=0;
  Fy:=0;
  FWhereX:=1;
  CurX:=1;
  CurY:=1;
  FWhereY:=1;
  FAttr:=7;
  Fline:=0;
  Lines:=1;
  GotAnsi  := False;
  GotPipe  := False;
  PipeCode := '';
  setlength(data,2);
  FillChar (Data, SizeOf(Data), 0);
  FCharHeight:=GetCharHeight;
  FCharWidth:=GetCharWidth;
  Buffer.Width:=132*FCharWidth;
  Buffer.Height:=100;
  FSl:=TStringList.Create;
  fillbyte(DosPal,0,sizeof(DosPal));
  ResetControlCode;
end;
{
procedure TANSIPaintbox.LoadXDefaultColors;
var
  tmpdc:tdoscolors;
Begin
  fillbyte(DosPal,0,sizeof(DosPal));
//  DosColors[0]:=Str2DosColor('000,000,000');
DosPal[0].r:=0;
DosPal[0].g:=0;
DosPal[0].b:=0;
  DosPal[1]:=Str2DosColor('000,000,128');
  DosPal[2]:=Str2DosColor('000,128,000');
  DosPal[3]:=Str2DosColor('000,128,128');
  DosPal[4]:=Str2DosColor('170,000,000');
  DosPal[5]:=Str2DosColor('128,000,128');
  DosPal[6]:=Str2DosColor('128,128,000');
  DosPal[7]:=Str2DosColor('192,192,192');
  DosPal[8]:=Str2DosColor('128,128,128');
  DosPal[9]:=Str2DosColor('000,000,255');
  DosPal[10]:=Str2DosColor('000,255,000');
  DosPal[11]:=Str2DosColor('000,255,255');
  DosPal[12]:=Str2DosColor('255,000,000');
  DosPal[13]:=Str2DosColor('255,000,255');
  DosPal[14]:=Str2DosColor('255,255,000');
  DosPal[15]:=Str2DosColor('255,255,255');

end;       }

procedure TANSIPaintbox.LoadXDefaultColors;
var
  tmpdc:tdoscolors;
Begin
  fillbyte(DosPal,0,sizeof(DosPal));
//  DosColors[0]:=Str2DosColor('000,000,000');
DosPal[0].r:=0;
DosPal[0].g:=0;
DosPal[0].b:=0;
  DosPal[1]:=Str2DosColor('000,000,173');
  DosPal[2]:=Str2DosColor('000,170,000');
  DosPal[3]:=Str2DosColor('000,170,173');
  DosPal[4]:=Str2DosColor('173,000,000');
  DosPal[5]:=Str2DosColor('173,000,173');
  DosPal[6]:=Str2DosColor('173,85,000');
  DosPal[7]:=Str2DosColor('173,170,173');
  DosPal[8]:=Str2DosColor('82,85,82');
  DosPal[9]:=Str2DosColor('82,85,255');
  DosPal[10]:=Str2DosColor('82,255,82');
  DosPal[11]:=Str2DosColor('82,255,255');
  DosPal[12]:=Str2DosColor('255,82,85');
  DosPal[13]:=Str2DosColor('255,85,255');
  DosPal[14]:=Str2DosColor('255,255,82');
  DosPal[15]:=Str2DosColor('255,255,255');
end;

function TANSIPaintbox.GetCharWidth: Byte;
begin
  Result:=Buffer.Canvas.TextWidth('0');
end;

function TANSIPaintbox.GetCharHeight: Byte;
begin
  Result:=Buffer.Canvas.TextHeight('0');
end;

procedure TANSIPaintbox.ResetControlCode;
begin
  Escape := 0;
  Code   := '';
end;

function TANSIPaintbox.ParseNumber(var Line: String): Integer;
Var
  A    : Integer;
  B    : LongInt;
  Str1 : String;
  Str2 : String;
Begin
  Str1 := Line;

  Val(Str1, A, B);

  If B = 0 Then
    Str1 := ''
  Else Begin
    Str2 := Copy(Str1, 1, B - 1);

    Delete (Str1, 1, B);
    Val    (Str2, A, B);
  End;

  Line        := Str1;
  ParseNumber := A;

end;

function TANSIPaintbox.AddChar(Ch: Char): Boolean;
begin
  AddChar := False;

    Data[CurY][CurX].Ch   := Ch;
    Data[CurY][CurX].Attr := FAttr;

    If CurX < ConWidth Then
      Inc (CurX)
    Else Begin
      If CurY = MaxMsgLines Then Begin
        AddChar := True;
        Exit;
      End Else Begin
        CurX := 1;
        Inc (CurY);
        setlength(data,length(data)+1);
      End;
    End;
end;

procedure TANSIPaintbox.MoveXY(X, Y: Word);
begin
    If X > ConWidth             Then X := ConWidth;
      If Y > Length(Data) Then Y := Length(Data);

      CurX := X;
      CurY := Y;
end;

procedure TANSIPaintbox.MoveUP;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber (Code);

  If Offset = 0 Then Offset := 1;

  If (CurY - Offset) < 1 Then
    NewPos := 1
  Else
    NewPos := CurY - Offset;

  MoveXY (CurX, NewPos);
  ResetControlCode;

end;

procedure TANSIPaintbox.MoveDOWN;
Var
  NewPos : Byte;
Begin
  NewPos := ParseNumber (Code);

  If NewPos = 0 Then NewPos := 1;

  MoveXY (CurX, CurY + NewPos);

  ResetControlCode;

end;

procedure TANSIPaintbox.MoveLEFT;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber (Code);

  If Offset = 0 Then Offset := 1;

  If CurX - Offset < 1 Then
    NewPos := 1
  Else
    NewPos := CurX - Offset;

  MoveXY (NewPos, CurY);

  ResetControlCode;

end;

procedure TANSIPaintbox.MoveRIGHT;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber(Code);

  If Offset = 0 Then Offset := 1;

  If CurX + Offset > ConWidth Then Begin
    NewPos := (CurX + Offset) - ConWidth;
    Inc (CurY);
  End Else
    NewPos := CurX + Offset;

  MoveXY (NewPos, CurY);

  ResetControlCode;

end;

procedure TANSIPaintbox.MoveCursor;
Var
  X : Byte;
  Y : Byte;
Begin
  X := ParseNumber(Code);
  Y := ParseNumber(Code);

  If X = 0 Then X := 1;
  If Y = 0 Then Y := 1;

  MoveXY (X, Y);

  ResetControlCode;

end;

procedure TANSIPaintbox.CheckCode(Ch: Char);
Var
  Temp1 : Byte;
  Temp2 : Byte;
Begin
  Case Ch of
    '0'..'9', ';', '?' : Code := Code + Ch;
    'H', 'f'      : MoveCursor;
    'A'           : MoveUP;
    'B'           : MoveDOWN;
    'C'           : MoveRIGHT;
    'D'           : MoveLEFT;
    'J'           : Begin
                      {ClearScreenData;}
                      ResetControlCode;
                    End;
    'K'           : Begin
                      Temp1 := CurX;
                      For Temp2 := CurX To ConWidth Do
                        AddChar(' ');
                      MoveXY (Temp1, CurY);
                      ResetControlCode;
                    End;
    'h'           : ResetControlCode;
    'm'           : Begin
                      While Length(Code) > 0 Do Begin
                        Case ParseNumber(Code) of
                          0 : FAttr := 7;
                          1 : FAttr := FAttr OR $08;
                          5 : FAttr := FAttr OR $80;
                          7 : Begin
                                FAttr := FAttr AND $F7;
                                FAttr := ((FAttr AND $70) SHR 4) + ((FAttr AND $7) SHL 4) + FAttr AND $80;
                              End;
                          30: FAttr := (FAttr AND $F8) + 0;
                          31: FAttr := (FAttr AND $F8) + 4;
                          32: FAttr := (FAttr AND $F8) + 2;
                          33: FAttr := (FAttr AND $F8) + 6;
                          34: FAttr := (FAttr AND $F8) + 1;
                          35: FAttr := (FAttr AND $F8) + 5;
                          36: FAttr := (FAttr AND $F8) + 3;
                          37: FAttr := (FAttr AND $F8) + 7;
                          40: TextBackGround (0);
                          41: TextBackGround (4);
                          42: TextBackGround (2);
                          43: TextBackGround (6);
                          44: TextBackGround (1);
                          45: TextBackGround (5);
                          46: TextBackGround (3);
                          47: TextBackGround (7);
                        End;
                      End;

                      ResetControlCode;
                    End;
    's'           : Begin
                      SavedX := CurX;
                      SavedY := CurY;
                      ResetControlCode;
                    End;
    'u'           : Begin
                      MoveXY (SavedX, SavedY);
                      ResetControlCode;
                    End;
  Else
    ResetControlCode;
  End;

end;

procedure TANSIPaintbox.ProcessChar(Ch: Char);
Begin
  Case Escape of
    0 : Begin
          Case Ch of
            #27 : Escape := 1;
            #9  : MoveXY (CurX + 8, CurY);
            #12 : {Edit.ClearScreenData};
          Else
              AddChar (Ch);

            ResetControlCode;
          End;
        End;
    1 : If Ch = '[' Then Begin
           Escape  := 2;
           Code    := '';
           GotAnsi := True;
         End Else
           Escape := 0;
    2 : CheckCode(Ch);
  Else
    ResetControlCode;
  End;

end;

function TANSIPaintbox.ProcessBuf(var Buf; BufLen: Word): Boolean;
Var
  Count  : Word;
  SBuffer : Array[1..4096] of Char Absolute Buf;
Begin
  Result := False;

  For Count := 1 to BufLen Do Begin
    If CurY > Lines Then begin
       Lines := CurY;
       setlength(data,lines+1);
    end;
    Case SBuffer[Count] of
      #10 : If CurY = MaxMsgLines Then Begin
              Result  := True;
              GotAnsi := False;
              Break;
            End Else Begin
              CurY:=CurY+1;
              CurX := 1;
            End;

      #13 : Begin
              CurX := 1;
            end;
      #26 : Begin
              Result := True;
              Break;
            End;
    Else
      ProcessChar(SBuffer[Count]);
    End;
  End;

end;

procedure TANSIPaintbox.SetBFont(const TF: TFont);
begin
  Buffer.Canvas.Font:=FFont;
  GetCharWidth;
  GetCharHeight;
end;

end.

