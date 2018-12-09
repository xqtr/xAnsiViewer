unit viewtext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType;

type

  { TForm2 }

  TForm2 = class(TForm)
    Memo1: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure Memo1KeyPress(Sender: TObject; var Key: char);
  private

  public

  end;

var
  Form2: TForm2;
  mchanged:boolean = false;
  filename:string;

implementation

uses unit1;

{$R *.lfm}

{ TForm2 }

procedure TForm2.Memo1KeyPress(Sender: TObject; var Key: char);
begin
  mchanged:=true;
  if key=chr(27) then
    begin
        key := #0;
        Close;
    end;
end;

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if mchanged and (filename<>'') and (memo1.readonly=false) then begin
    if MessageDlg('Text Changed', 'Save changes?', mtConfirmation,[mbYes, mbNo],0) = mrYes then begin
      memo1.lines.savetofile(filename);
      form1.pb.clearcanvas;
      form1.pb.loadfromfile(form1.opendialog.filename);
    end;
  end;
  mchanged:=false;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Form1.KeyPreview := True;
end;

procedure TForm2.FormKeyPress(Sender: TObject; var Key: char);
begin
//  if key=#27 then form2.close;
  if key=chr(27) then
    begin
        key := #0;
        Close;
    end;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  form2.Font:=form1.pb.font;
end;

end.

