// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2017 Salvador D�az Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uChildForm;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Menus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Types, Vcl.ComCtrls, Vcl.ClipBrd,
  System.UITypes,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Menus,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Types, ComCtrls, ClipBrd,
  {$ENDIF}
  uMainForm, uCEFChromium, uCEFWindowParent, uCEFInterfaces;

type
  TChildForm = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Chromium1: TChromium;
    CEFWindowParent1: TCEFWindowParent;
    Timer1: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure Chromium1LoadEnd(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; httpStatusCode: Integer);
    procedure Chromium1Close(Sender: TObject; const browser: ICefBrowser;
      out Result: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True when the final timer is triggered
    FClosing  : boolean;  // Set to True in the CloseQuery event.

  protected
    procedure BrowserCreatedMsg(var aMessage : TMessage); message CEFBROWSER_CREATED;
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;

  public
    property Closing   : boolean    read FClosing;
  end;

implementation

{$R *.dfm}

// Destruction steps
// =================
// 1. Load about:blank and wait till it's fully loaded
// 2. Call TChromium.CloseBrowser
// 3. Wait for the TChromium.Close
// 4. Enable a Timer and wait for 2 seconds
// 5. Close and destroy the form

procedure TChildForm.Button1Click(Sender: TObject);
begin
  Chromium1.LoadURL(Edit1.Text);
end;

procedure TChildForm.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  PostMessage(Handle, CEFBROWSER_CREATED, 0, 0);
end;

procedure TChildForm.Chromium1Close(Sender: TObject; const browser: ICefBrowser; out Result: Boolean);
begin
  Timer1.Enabled := True;
end;

procedure TChildForm.Chromium1LoadEnd(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  httpStatusCode: Integer);
begin
  if FClosing and (Chromium1.DocumentURL = 'about:blank') then
    Chromium1.CloseBrowser(False);
end;

procedure TChildForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TChildForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) and Panel1.Enabled then
    begin
      FClosing := True;
      Chromium1.LoadURL('about:blank');
    end;
end;

procedure TChildForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TChildForm.FormDestroy(Sender: TObject);
begin
  // Tell the main form that a child has been destroyed.
  // The main form will check if this was the last child to close itself
  PostMessage(MainForm.Handle, CEFBROWSER_CHILDDESTROYED, 0, 0);
end;

procedure TChildForm.FormShow(Sender: TObject);
begin
  Chromium1.CreateBrowser(CEFWindowParent1, '');
end;

procedure TChildForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;

  if not(FCanClose) then
    begin
      FCanClose := True;
      PostMessage(self.Handle, WM_CLOSE, 0, 0);
    end;
end;

procedure TChildForm.WMMove(var aMessage : TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.WMMoving(var aMessage : TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.BrowserCreatedMsg(var aMessage : TMessage);
begin
  Panel1.Enabled := True;
  Button1.Click;
end;

end.
