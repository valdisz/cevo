unit battle;

interface

uses
  ScreenTools, Protocol, Messg, ButtonBase, ButtonA,
  LCLIntf, LCLType,
  SysUtils, Classes, Graphics, Controls, Forms;

type
  TBattleDlg = class(TDrawDlg)
    OKBtn: TButtonA;
    CancelBtn: TButtonA;
    procedure FormPaint(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
  public
    uix, ToLoc: integer;
    Forecast: TBattleForecastEx;
    IsSuicideQuery: boolean;
  end;

var
  BattleDlg: TBattleDlg;

procedure PaintBattleOutcome(ca: TCanvas; xm, ym, uix, ToLoc: integer;
  Forecast: TBattleForecastEx);


implementation

uses
  Types,
  Term, ClientTools, IsoEngine;

{$R *.lfm}

const
  Border = 3;
  MessageLineSpacing = 20;

  DamageColor = $0000E0;
  FanaticColor = $800080;
  FirstStrikeColor = $A0A0A0;


procedure PaintBattleOutcome(ca: TCanvas; xm, ym, uix, ToLoc: integer;
  Forecast: TBattleForecastEx);
var
  euix, ADamage, DDamage, StrMax, DamageMax, MaxBar, LAStr, LDStr,
  LADamage, LDDamage, LABaseDamage, LAAvoidedDamage, LDBaseDamage: integer;
  //TerrType: Cardinal;
  UnitInfo: TUnitInfo;
  TextSize: TSize;
  LabelText: string;
  FirstStrike: boolean;
begin
  MaxBar := 65;

  //TerrType:=MyMap[ToLoc] and fTerrain;
  GetUnitInfo(ToLoc, euix, UnitInfo);

  FirstStrike := (MyModel[MyUn[uix].mix].Cap[mcFirst] > 0) and
    (Forecast.DBaseDamage >= UnitInfo.Health);
  ADamage := MyUn[uix].Health - Forecast.EndHealthAtt;
  if FirstStrike then
    ADamage := ADamage + Forecast.ABaseDamage div 2;
  DDamage := UnitInfo.Health - Forecast.EndHealthDef;
  if Forecast.AStr > Forecast.DStr then
    StrMax := Forecast.AStr
  else
    StrMax := Forecast.DStr;
  if ADamage > DDamage then
    DamageMax := ADamage
  else
    DamageMax := DDamage;
  if Forecast.ABaseDamage > Forecast.DBaseDamage then
    StrMax := StrMax * DamageMax div Forecast.ABaseDamage
  else
    StrMax := StrMax * DamageMax div Forecast.DBaseDamage;

  LAStr := Forecast.AStr * MaxBar div StrMax;
  LDStr := Forecast.DStr * MaxBar div StrMax;
  LADamage := ADamage * MaxBar div DamageMax;
  LABaseDamage := Forecast.ABaseDamage * MaxBar div DamageMax;
  if FirstStrike then
    LAAvoidedDamage := LABaseDamage div 2
  else
    LAAvoidedDamage := 0;
  LDDamage := DDamage * MaxBar div DamageMax;
  LDBaseDamage := Forecast.DBaseDamage * MaxBar div DamageMax;

  DarkGradient(ca, xm - 8 - LAStr, ym - 8, LAStr, 2);
  VDarkGradient(ca, xm - 8, ym - 8 - LDStr, LDStr, 2);
  LightGradient(ca, xm + 8, ym - 8, LDBaseDamage, DamageColor);
  if LDDamage > LDBaseDamage then
    LightGradient(ca, xm + 8 + LDBaseDamage, ym - 8, LDDamage - LDBaseDamage, FanaticColor);
  if LAAvoidedDamage > 0 then
    VLightGradient(ca, xm - 8, ym + 8, LAAvoidedDamage, FirstStrikeColor);
  VLightGradient(ca, xm - 8, ym + 8 + LAAvoidedDamage, LABaseDamage - LAAvoidedDamage,
    DamageColor);
  if LADamage > LABaseDamage then
    VLightGradient(ca, xm - 8, ym + 8 + LABaseDamage, LADamage - LABaseDamage, FanaticColor);
  BitBltTransparent(ca, xm - 12, ym - 12, 24, 24,
    26, 146, system1transparent);

  LabelText := Format('%d', [Forecast.AStr]);
  TextSize := ca.TextExtent(LabelText);
  if TextSize.cx div 2 + 2 > LAStr div 2 then
    RisedTextOut(ca, xm - 10 - TextSize.cx, ym - (TextSize.cy + 1) div 2, LabelText)
  else
    RisedTextOut(ca, xm - 8 - (LAStr + TextSize.cx) div 2, ym - (TextSize.cy + 1) div 2, LabelText);

  LabelText := Format('%d', [Forecast.DStr]);
  TextSize := ca.TextExtent(LabelText);
  if TextSize.cy div 2 > LDStr div 2 then
    RisedTextOut(ca, xm - (TextSize.cx + 1) div 2, ym - 8 - TextSize.cy, LabelText)
  else
    RisedTextOut(ca, xm - (TextSize.cx + 1) div 2, ym - 8 - (LDStr + TextSize.cy) div 2, LabelText);

  if Forecast.EndHealthDef <= 0 then
  begin
    BitBltTransparent(ca, xm + 8 + LDDamage - 7, ym - 7, 14, 17,
      51, 153, system1transparent);
  end;
  LabelText := Format('%d', [DDamage]);
  TextSize := ca.TextExtent(LabelText);
  if TextSize.cx div 2 + 2 > LDDamage div 2 then
  begin
    if Forecast.EndHealthDef > 0 then
      RisedTextOut(ca, xm + 10, ym - (TextSize.cy + 1) div 2, LabelText);
  end
  else
    RisedTextOut(ca, xm + 8 + (LDDamage - TextSize.cx) div 2, ym - (TextSize.cy + 1) div 2, LabelText);

  if Forecast.EndHealthAtt <= 0 then
  begin
    BitBltTransparent(ca, xm - 7, ym + 8 + LADamage - 7, 14, 17,
      51, 153, system1transparent);
  end;
  LabelText := Format('%d', [MyUn[uix].Health - Forecast.EndHealthAtt]);
  TextSize := ca.TextExtent(LabelText);
  if TextSize.cy div 2 > (LADamage - LAAvoidedDamage) div 2 + LAAvoidedDamage then
  begin
    if Forecast.EndHealthAtt > 0 then
      RisedTextOut(ca, xm - (TextSize.cx + 1) div 2, ym + 8 + LAAvoidedDamage, LabelText);
  end
  else
    RisedTextOut(ca, xm - (TextSize.cx + 1) div 2, ym + 8 + LAAvoidedDamage +
      (LADamage - LAAvoidedDamage - TextSize.cy) div 2, LabelText);

  NoMap.SetOutput(Buffer);
  BitBltUgly(Buffer.Canvas, 0, 0, 66, 48, ca, xm + 8 + 4, ym - 8 - 12 - 48, SRCCOPY);
  NoMap.PaintUnit(1, 0, UnitInfo, 0);
  BitBltUgly(ca, xm + 8 + 4, ym - 8 - 12 - 48, 66, 48, Buffer.Canvas, 0, 0, SRCCOPY);

  BitBltUgly(Buffer.Canvas, 0, 0, 66, 48, ca, xm - 8 - 4 - 66, ym + 8 + 12, SRCCOPY);
  MakeUnitInfo(me, MyUn[uix], UnitInfo);
  UnitInfo.Flags := UnitInfo.Flags and not unFortified;
  NoMap.PaintUnit(1, 0, UnitInfo, 0);
  BitBltUgly(ca, xm - 8 - 4 - 66, ym + 8 + 12, 66, 48, Buffer.Canvas, 0, 0, SRCCOPY);
end; {PaintBattleOutcome}


procedure TBattleDlg.FormCreate(Sender: TObject);
begin
  OKBtn.Caption := Phrases.Lookup('BTN_YES');
  CancelBtn.Caption := Phrases.Lookup('BTN_NO');
  InitButtons();
end;

procedure TBattleDlg.FormShow(Sender: TObject);
begin
  if IsSuicideQuery then
  begin
    ClientWidth := 300;
    ClientHeight := 288;
    OKBtn.Visible := True;
    CancelBtn.Visible := True;
    Left := (Screen.Width - ClientWidth) div 2; // center on screen
    Top := (Screen.Height - ClientHeight) div 2;
  end
  else
  begin
    ClientWidth := 178;
    ClientHeight := 178;
    OKBtn.Visible := False;
    CancelBtn.Visible := False;
  end;
end;

procedure TBattleDlg.FormPaint(Sender: TObject);
var
  ym, cix, p: integer;
  s, s1: string;
begin
  with Canvas do
  begin
    Brush.Color := 0;
    FillRect(Rect(0, 0, ClientWidth, ClientHeight));
    Brush.Style := bsClear;
    PaintBackground(self, 3 + Border, 3 + Border, ClientWidth - (6 + 2 * Border),
      ClientHeight - (6 + 2 * Border));
  end;
  Frame(Canvas, Border + 1, Border + 1, ClientWidth - (2 + Border), ClientHeight - (2 + Border),
    MainTexture.clBevelLight, MainTexture.clBevelShade);
  Frame(Canvas, 2 + Border, 2 + Border, ClientWidth - (3 + Border), ClientHeight - (3 + Border),
    MainTexture.clBevelLight, MainTexture.clBevelShade);

  if IsSuicideQuery then
  begin
    Canvas.Font.Assign(UniFont[ftCaption]);
    s := Phrases.Lookup('TITLE_SUICIDE');
    RisedTextout(Canvas, (ClientWidth - BiColorTextWidth(Canvas, s)) div 2, 7 + Border, s);
    Canvas.Font.Assign(UniFont[ftNormal]);
    s := Phrases.Lookup('SUICIDE');
    p := pos('\', s);
    if p = 0 then
      RisedTextout(Canvas, (ClientWidth - BiColorTextWidth(Canvas, s)) div 2, 205, s)
    else
    begin
      s1 := copy(s, 1, p - 1);
      RisedTextout(Canvas, (ClientWidth - BiColorTextWidth(Canvas, s1)) div 2,
        205 - MessageLineSpacing div 2, s1);
      s1 := copy(s, p + 1, 255);
      RisedTextout(Canvas, (ClientWidth - BiColorTextWidth(Canvas, s1)) div 2,
        205 + (MessageLineSpacing - MessageLineSpacing div 2), s1);
    end;
    ym := 110;
  end
  else
    ym := ClientHeight div 2;
  Canvas.Font.Assign(UniFont[ftSmall]);
  PaintBattleOutcome(Canvas, ClientWidth div 2, ym, uix, ToLoc, Forecast);

  for cix := 0 to ControlCount - 1 do
    if (Controls[cix].Visible) and (Controls[cix] is TButtonBase) then
      BtnFrame(Canvas, Controls[cix].BoundsRect, MainTexture);
end;

procedure TBattleDlg.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if not IsSuicideQuery then
    Close;
end;

procedure TBattleDlg.FormDeactivate(Sender: TObject);
begin
  if not IsSuicideQuery then
    Close;
end;

procedure TBattleDlg.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if not IsSuicideQuery and (Key <> VK_SHIFT) then
  begin
    Close;
    MainScreen.Update;
    if Key <> VK_ESCAPE then
      MainScreen.FormKeyDown(Sender, Key, Shift);
  end;
end;

procedure TBattleDlg.OKBtnClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TBattleDlg.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
