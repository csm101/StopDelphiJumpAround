unit StopJumpAroundPluginDataModule;

interface

uses
  ToolsAPI, VCL.Menus, VCL.ActnList,VCL.Forms,Winapi.Messages,   Vcl.Dialogs,
  Winapi.Windows, System.SysUtils, System.Classes, Winapi.ActiveX, System.TypInfo, DockForm, DesignIntf,
  Vcl.Graphics, Vcl.ImgList, Vcl.Controls, Vcl.ComCtrls, Vcl.Themes, Xml.XMLIntf, System.IniFiles,
  System.Types, PersonalityConst, System.ImageList, Vcl.AppEvnts;

type
  TMainPlugin = class(TDataModule)
    images: TImageList;
  private
    LockWindowPosition: boolean;
    button : TToolButton;
    imagesStartIndex:integer;

    FOrigWndProc: TWndMethod;
    FSubclassed: Boolean;
    FLastAllowedWindowChangingTimestamp:TDateTime;

    procedure CreateToolBar;
    procedure UpdateButton;
    procedure ToolbarButtonClick(sender:TObject);

    procedure SubclassMainForm;
    procedure UnsubclassMainForm;
    procedure CustomWndProc(var Message: TMessage);

  public
    destructor Destroy; override;
  end;

var
  MainPlugin: TMainPlugin;

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


procedure TMainPlugin.ToolbarButtonClick(sender:TObject);
begin
  LockWindowPosition := not LockWindowPosition;

  if LockWindowPosition then
    SubclassMainForm
  else
    UnsubclassMainForm;

  UpdateButton;
end;

procedure TMainPlugin.UpdateButton;
begin
  if LockWindowPosition then begin
    button.Hint := 'IDE will stay put where you placed it';
    button.ImageIndex := imagesStartIndex+1;
  end else begin
    button.Hint := 'IDE will jump around whenever you start/stop the debugger';
    button.ImageIndex := imagesStartIndex;
  end;
end;


procedure TMainPlugin.CreateToolBar;
var NTAServices:INTAServices;
begin
  if not Supports(BorlandIDEServices, INTAServices, NTAServices) then begin
    exit;
  end;
  imagesStartIndex  := NTAServices.addImages(images);

  //toolbar := NTAServices.NewToolbar('Digisoft','Digisoft');
  var toolbar := NTAServices.GetToolbar(sViewToolBar);
  button := TToolButton.Create(toolbar);
  button.parent := toolbar;
  button.ImageIndex := imagesStartIndex;
  button.OnClick := ToolbarButtonClick;
  button.visible := true;
  button.ShowHint := true;
  updatebutton;
end;


var thePlugin:TMainPlugin = nil;

destructor TMainPlugin.Destroy;
begin
  UnsubclassMainForm;
  if button<>nil then begin
    button.parent := nil;
    button.free;
  end;
  inherited;
end;


procedure TMainPlugin.CustomWndProc(var Message: TMessage);


   function IsWindowsPosChangingMessageToBeHandled:boolean;
   begin
     result := false;
     if message.Msg <>WM_WINDOWPOSCHANGING then exit;
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
  if IsWindowsPosChangingMessageToBeHandled  then
    WindowPosChanging(TWMWindowPosChanging(Message))
  else
    FOrigWndProc(message);
end;

initialization
  thePlugin:= TMainPlugin.create(nil);
  thePlugin.CreateToolbar;
finalization

  FreeAndNil(thePlugin);
end.

