object MainPlugin: TMainPlugin
  Height = 480
  Width = 640
  object SubclassTimer: TTimer
    OnTimer = SubclassTimerTimer
    Left = 24
    Top = 16
  end
end
