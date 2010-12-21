import mx.events.AIREvent;
import mx.events.FlexEvent;
import mx.events.MenuEvent;

private var settingWindow:SettingWindow;
private var timer:Timer;
private var interval:uint = 50;
private var logFile:File;
private var fileStream:FileStream;

private var lastModified:Date;
private var logText:String;

private var configXML:XML;
private var config:File;
private var configFileStream:FileStream;
private static const CONFIG_XML_NAME:String = "trace-rabbit-config.xml";

protected function playPauseButton_clickHandler(event:MouseEvent):void {
  if (playPauseButton.selected) {
    playPauseButton.label = "àÍéûí‚é~";
    timer.start();
  } else {
    playPauseButton.label = "é¿çs";
    timer.stop();
  }
}

protected function windowedapplication1_applicationCompleteHandler(event:FlexEvent):void {
  autoExit = false;
  settingWindow = new SettingWindow();
  settingWindow.type = NativeWindowType.UTILITY;
  settingWindow.addEventListener(AIREvent.WINDOW_ACTIVATE, settingWindowActiveHandler);
  settingWindow.addEventListener(Event.CLOSING, settingWindowClosingHandler);
  settingWindow.addEventListener(Event.CLOSE, settingWindowCloseHandler);
  alwaysInFrontCheckBox.addEventListener(Event.CHANGE, alwaysInFrontCheckBoxSelectHandler);
  fileStream = new FileStream();
  configFileStream = new FileStream();
  timer = new Timer(interval);
  timer.addEventListener(TimerEvent.TIMER, readFile);
  timer.start();

  initConfig();
}

private function alwaysInFrontCheckBoxSelectHandler(event:Event):void {
  alwaysInFront = alwaysInFrontCheckBox.selected;
}

private function initConfig():void {
  config = File.documentsDirectory.resolvePath(CONFIG_XML_NAME);
  if (config.exists) {
    configFileStream.open(config, FileMode.READ);
    configXML = XML(configFileStream.readUTFBytes(configFileStream.bytesAvailable));
    alwaysInFrontCheckBox.selected = configXML.alwaysInFront == "true" ? true : false;
    settingWindow.path = configXML.logFile;
    alwaysInFront = alwaysInFrontCheckBox.selected;
  } else {
    //no config
    configFileStream.open(config, FileMode.WRITE);
    configXML = <config>
      <logFile></logFile>
      <alwaysInFront>false</alwaysInFront>
      <useUTF>false</useUTF>
      </config>
      configFileStream.writeUTFBytes(configXML);
    configFileStream.close();
  }

  if (configXML.logFile == "") {
    openSettingWindow();
  } else {
    loadLogFile();
  }
}

private function loadLogFile():void {
  if (settingWindow.path) {
    logFile = new File(settingWindow.path);
    readFile();
  }
}

private function saveConfig():void {
  if (settingWindow.filePath) {
    configXML.logFile = settingWindow.filePath.text;          
  }
  configXML.alwaysInFront = alwaysInFrontCheckBox.selected ? "true" : "false";
  configXML.useUTF = useUTFCheckBox.selected ? "true" : "false";

  configFileStream.open(config, FileMode.WRITE);
  configFileStream.writeUTFBytes(configXML);
  configFileStream.close();

}

protected function menu_changeHandler(event:MenuEvent):void {
  if (event.item.@data == "exit") {
    exit();
  } else if (event.item.@data == "setting") {
    openSettingWindow();
  }
}

private function openSettingWindow():void {
  settingWindow.open(true);
  settingWindow.visible = true;
  settingWindow.orderToFront();
  settingWindow.alwaysInFront = true;
}

private function settingWindowActiveHandler(event:AIREvent):void {
  settingWindow.filePath.text = settingWindow.path;
}

private function settingWindowClosingHandler(event:Event):void {
  event.preventDefault();
  settingWindow.visible = false;
  saveConfig();
  settingWindow.path = configXML.logFile;
}

private function settingWindowCloseHandler(event:Event):void {
  loadLogFile();
}

protected function windowedapplication1_closingHandler(event:Event):void {
  saveConfig();
  exit();
}


private function readFile(event:Event = null):void {
  if (!logFile || !logFile.exists) {
    return;
  }

  lastModified = logFile.modificationDate;
  fileStream.open(logFile, FileMode.READ);
  fileStream.position = 0;
  if (useUTFCheckBox.selected) {
    logText = fileStream.readUTFBytes(logFile.size);
  } else {
    logText = fileStream.readMultiByte(logFile.size, "shift-jis");
  }
  logText = logText.replace(/\r\n/g, "\n");
  output.text = logText;
  output.scrollToRange(int.MAX_VALUE);
  fileStream.close();
}

protected function iconbutton1_clickHandler(event:MouseEvent):void {
  output.text = "";
  if (logFile && logFile.exists) {
    fileStream.open(logFile, FileMode.WRITE);
    fileStream.writeUTFBytes("");
    fileStream.close();        
  }
}

