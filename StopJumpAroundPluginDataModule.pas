unit StopJumpAroundPluginDataModule;

interface

uses
  ToolsAPI, VCL.Menus, VCL.ActnList,VCL.Forms,Winapi.Messages,   Vcl.Dialogs,
  Winapi.Windows, System.SysUtils, System.Classes, Winapi.ActiveX, System.TypInfo, DockForm, DesignIntf,
  Vcl.Graphics, Vcl.ImgList, Vcl.Controls, Vcl.ComCtrls, Vcl.Themes, Xml.XMLIntf, System.IniFiles,
  System.Types, PersonalityConst, System.ImageList, Vcl.AppEvnts, Vcl.ExtCtrls;

type
  TMainPlugin = class(TDataModule)
    SubclassTimer: TTimer;
    procedure SubclassTimerTimer(Sender: TObject);
  private
    FOrigWndProc: TWndMethod;
    FSubclassed: Boolean;
    FLastAllowedWindowChangingTimestamp:TDateTime;

    procedure SubclassMainForm;
    procedure UnsubclassMainForm;
    procedure CustomWndProc(var Message: TMessage);

  public
    destructor Destroy; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}



procedure TMainPlugin.SubclassMainForm;
begin
  if FSubclassed then exit;
  if Application = nil then exit;
  if Application.MainForm = nil then exit;
  FOrigWndProc := Application.MainForm.WindowProc;
  Application.MainForm.WindowProc := CustomWndProc;
  FSubclassed := True;
end;


procedure TMainPlugin.UnsubclassMainForm;
begin
  if not FSubclassed then exit;
  if Application = nil then exit;
  if Application.MainForm = nil then exit;

  Application.MainForm.WindowProc := FOrigWndProc;
  FSubclassed := False;
end;

destructor TMainPlugin.Destroy;
begin
  UnsubclassMainForm;
  inherited;
end;

procedure TMainPlugin.CustomWndProc(var Message: TMessage);

   function IsWindowsPosChangingMessageToBeStopped:boolean;
   begin
     result := false;
     if IsIconic(Application.MainForm.Handle) then exit;
     // workaround for when the window gets frozen and invisible with its "iconized" size, even if it isn't iconic anymore
     if Application.MainForm.Width<200 then exit;  
     if Application.MainForm.Height<200 then exit;
     if (GetKeyState(VK_LWIN)<0)  or (GetKeyState(VK_LBUTTON) < 0) then begin
        // if I am allowing the movement because user is using the mouse or using windows+left/right/top/bottom shortcuts
        // i allow subsequents moves for a couple of seconds in order to allow the movements caused by "window snapping"
        // to the screen borders done the operating system
        FLastAllowedWindowChangingTimestamp := now;
        exit; //user could be dragging the window
     end;
     if (now - FLastAllowedWindowChangingTimestamp) < (2/24/60/60) then
       exit;
     result := true;
   end;

   procedure WindowPosChanging(var message:TWMWindowPosChanging);
   begin
     message.WindowPos.flags := message.WindowPos.flags or SWP_NOMOVE or SWP_NOSIZE;
     message.Result := 0;
   end;

begin
  case  message.Msg of
    WM_WINDOWPOSCHANGING:
      if IsWindowsPosChangingMessageToBeStopped then begin
        WindowPosChanging(TWMWindowPosChanging(Message));
        exit;
      end;
    WM_SYSCOMMAND:
      begin
        var cmd := message.WParam;
        if (cmd = SC_MINIMIZE) or (cmd = SC_MAXIMIZE) or (cmd = SC_RESTORE) then
          FLastAllowedWindowChangingTimestamp := now;
      end;
    WM_NCLBUTTONDOWN:
      begin
         var hit := Message.WParam;
         if (hit = HTMAXBUTTON) or (hit = HTMINBUTTON) or (hit = HTCAPTION) then
          FLastAllowedWindowChangingTimestamp := now;
      end;
  end;

  FOrigWndProc(message);
end;

var thePlugin:TMainPlugin =nil;
procedure TMainPlugin.SubclassTimerTimer(Sender: TObject);
begin
   // i try multiple times until the main form has been created
   SubclassMainForm;
   if FSubclassed then
     SubclassTimer.Enabled:=false;
end;

initialization
  thePlugin:= TMainPlugin.create(nil);
finalization

  FreeAndNil(thePlugin);
end.

