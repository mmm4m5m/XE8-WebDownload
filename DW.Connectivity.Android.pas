unit DW.Connectivity.Android;

{*******************************************************}
{                                                       }
{                    Kastri Free                        }
{                                                       }
{          DelphiWorlds Cross-Platform Library          }
{                                                       }
{*******************************************************}

// org: {$I DW.GlobalDefines.inc}
interface

uses
  // Android
  Androidapi.JNI.Net, Androidapi.JNI.GraphicsContentViewText,
  // DW
  // org: DW.MultiReceiver.Android, DW.Connectivity;
  DW.Connectivity;

type
  TPlatformConnectivity = class;

// org:
{
  TConnectivityReceiver = class(TMultiReceiver)
  private
    FPlatformConnectivity: TPlatformConnectivity;
  protected
    procedure Receive(context: JContext; intent: JIntent); override;
    procedure ConfigureActions; override;
  public
    constructor Create(const APlatformConnectivity: TPlatformConnectivity);
  end;
//}

  TPlatformConnectivity = class(TObject)
  private
    FConnectivity: TConnectivity;
    // org: FReceiver: TConnectivityReceiver;
  private
    class function ConnectivityManager: JConnectivityManager; static;
  protected
    procedure ConnectivityChange;
  public
    class function GetConnectedNetworkInfo: JNetworkInfo; static;
    class function IsConnectedToInternet: Boolean; static;
    class function IsWifiInternetConnection: Boolean; static;
  public
    constructor Create(const AConnectivity: TConnectivity);
    destructor Destroy; override;
  end;

implementation

uses
  // Android
  Androidapi.JNI.JavaTypes, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNIBridge, Androidapi.JNI;

type
  TOpenConnectivity = class(TConnectivity);

{ TConnectivityReceiver }

// org:
{
constructor TConnectivityReceiver.Create(const APlatformConnectivity: TPlatformConnectivity);
begin
  inherited Create;
  FPlatformConnectivity := APlatformConnectivity;
end;

procedure TConnectivityReceiver.ConfigureActions;
begin
  IntentFilter.addAction(TJConnectivityManager.JavaClass.CONNECTIVITY_ACTION);
end;

procedure TConnectivityReceiver.Receive(context: JContext; intent: JIntent);
begin
  FPlatformConnectivity.ConnectivityChange;
end;
//}

{ TPlatformConnectivity }

constructor TPlatformConnectivity.Create(const AConnectivity: TConnectivity);
begin
  inherited Create;
  FConnectivity := AConnectivity;
  // org: FReceiver := TConnectivityReceiver.Create(Self);
end;

destructor TPlatformConnectivity.Destroy;
begin
  // org: FReceiver.Free;
  inherited;
end;

class function TPlatformConnectivity.ConnectivityManager: JConnectivityManager;
var
  LService: JObject;
begin
  // org: LService := TAndroidHelper.Context.getSystemService(TJContext.JavaClass.CONNECTIVITY_SERVICE);
  LService := SharedActivityContext.getSystemService(TJContext.JavaClass.CONNECTIVITY_SERVICE);
  Result := TJConnectivityManager.Wrap(LService);
end;

// Based on: https://github.com/jamesmontemagno/ConnectivityPlugin/issues/56
class function TPlatformConnectivity.GetConnectedNetworkInfo: JNetworkInfo;
var
  LManager: JConnectivityManager;
  // org: LAllNetworks: TJavaObjectArray<JNetwork>;
  // org: LAllNetworkInfo: TJavaObjectArray<JNetworkInfo>;
  LInfo: JNetworkInfo;
  // org: LCapabilities: JNetworkCapabilities;
  // org: I: Integer;
begin
  Result := nil;
  LManager := ConnectivityManager;
// org:
{
  if TJBuild_VERSION.JavaClass.SDK_INT >= 21 then
  begin
    LAllNetworks := LManager.getAllNetworks;
    for I := 0 to LAllNetworks.Length - 1 do
    begin
      LCapabilities := LManager.getNetworkCapabilities(LAllNetworks[I]);
      // Check if the network has internet capability
      if (LCapabilities <> nil) and LCapabilities.hasCapability(TJNetworkCapabilities.JavaClass.NET_CAPABILITY_INTERNET) then
      begin
        // ..and is Validated or SDK < 23
        if (TJBuild_VERSION.JavaClass.SDK_INT < 23) or LCapabilities.hasCapability(TJNetworkCapabilities.JavaClass.NET_CAPABILITY_VALIDATED) then
        begin
          LInfo := LManager.getNetworkInfo(LAllNetworks[I]);
          if (LInfo <> nil) and LInfo.isAvailable and LInfo.isConnected then
          begin
            Result := LInfo;
            Break;
          end;
        end;
      end;
    end;
  end
  else
//}
// org:
{
  begin
    LAllNetworkInfo := LManager.getAllNetworkInfo;
    for I := 0 to LAllNetworkInfo.Length - 1 do
    begin
      LInfo := LAllNetworkInfo[I];
      if (LInfo <> nil) and LInfo.isAvailable and LInfo.isConnected then
      begin
        Result := LInfo;
        Break;
      end;
    end;
  end;
//}
// new:
  LInfo := LManager.getActiveNetworkInfo;
  if (LInfo <> nil) and LInfo.isAvailable and LInfo.isConnected then
    Result := LInfo;
end;

class function TPlatformConnectivity.IsConnectedToInternet: Boolean;
begin
  Result := GetConnectedNetworkInfo <> nil;
end;

class function TPlatformConnectivity.IsWifiInternetConnection: Boolean;
var
  LInfo: JNetworkInfo;
begin
  LInfo := GetConnectedNetworkInfo;
  Result := (LInfo <> nil) and (LInfo.getType = TJConnectivityManager.JavaClass.TYPE_WIFI);
end;

procedure TPlatformConnectivity.ConnectivityChange;
begin
  TOpenConnectivity(FConnectivity).DoConnectivityChange(IsConnectedToInternet);
end;

end.

