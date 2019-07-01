object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 294
  ClientWidth = 386
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 48
    Width = 370
    Height = 50
    Max = 5000
    Step = 1
    TabOrder = 5
  end
  object ProgressBar2: TProgressBar
    Left = 8
    Top = 136
    Width = 370
    Height = 50
    Max = 5000
    MarqueeInterval = 1
    Step = 1
    TabOrder = 6
  end
  object btnStart: TButton
    Left = 15
    Top = 254
    Width = 75
    Height = 26
    Caption = 'Start'
    Enabled = False
    TabOrder = 2
    OnClick = btnStartClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 16
    Width = 153
    Height = 26
    ReadOnly = True
    TabOrder = 3
    WordWrap = False
  end
  object Memo2: TMemo
    Left = 8
    Top = 104
    Width = 153
    Height = 26
    ReadOnly = True
    TabOrder = 7
    WordWrap = False
  end
  object btnSelectFolder: TButton
    Left = 15
    Top = 223
    Width = 75
    Height = 25
    Caption = 'Choose Folder'
    Enabled = False
    TabOrder = 1
    OnClick = btnSelectFolderClick
  end
  object mmDataFiles: TMemo
    Left = 167
    Top = 223
    Width = 211
    Height = 61
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -7
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 8
    WantReturns = False
    WordWrap = False
  end
  object Times1: TMemo
    Left = 167
    Top = 16
    Width = 211
    Height = 26
    Enabled = False
    Lines.Strings = (
      'For Future Use')
    ReadOnly = True
    TabOrder = 4
    WordWrap = False
  end
  object btnServer: TButton
    Left = 15
    Top = 192
    Width = 363
    Height = 25
    Caption = 'Connect to Server'
    TabOrder = 0
    OnClick = btnServerClick
  end
  object rgMulti: TRadioGroup
    Left = 96
    Top = 223
    Width = 65
    Height = 63
    Caption = 'Multithread'
    ItemIndex = 1
    Items.Strings = (
      'On'
      'Off')
    TabOrder = 9
  end
end
