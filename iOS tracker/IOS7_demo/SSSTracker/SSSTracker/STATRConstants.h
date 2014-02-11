//
//  defines.h
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 4/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#define kTimeoutInterval 30     // sec timeout for http request

#define MaxStatEventsBufferSize 50*1024     //50Kb
#define MaxStatEventsFolderFilesSize 20 * 1024 * 1024       //20Mb
#define SendAfterStartIntervalSec 2
#define SendSuccessIntervalSec 15
#define SendErrorIntervalSec 60 * 60

#define SettingDefErrorCode 0
#define SettingDefCollectData NO
#define SettingDefSendData NO
#define SettingDefWaitTimeout 0
#define SettingDefIsEnabledAutomaticDataSending YES
#define SettingMaxWaitTimeout 7 * 24 * 60 * 60

#define SettingStorageKeyCollectData @"SSSCollectData"
#define SettingStorageKeySendData @"SSSSendData"
#define SettingStorageKeyWaitTimeout @"SSSWaitTimeout"
#define SettingStorageKeySettingsPreviousConnectionTime @"SSSSettingsPreviousConnectionTime"
#define SettingStorageKeyIsEnabledAutomaticDataSending @"SSSIsEnabledAutomaticDataSending"

#define ERROR_OK 0
#define ERROR_INVALID_PROJECT 10
#define ERROR_IP_IS_BLOCKED 20
#define ERROR_APP_VER_IS_BLOCKED 30
#define ERROR_APP_IS_BLOCKED 31
#define ERROR_TRACKER_VER_IS_INVALID 35
#define ERROR_DATA_PACKAGE_IS_INVALID 40
#define ERROR_INTERNAL_SERVER_ERROR 50

#define StatTagPackage @"package"
#define StatTagEvent @"event"
#define StatTagParam @"param"
#define StatAttrProductKey @"product"
#define StatAttrInstallationKey @"installation"
#define StatAttrExecutionKey @"execution"
#define StatAttrDateTime @"dt"
#define StatAttrOrder @"ord"
#define StatAttrName @"name"
#define StatAttrType @"type"
#define StatAttrValue @"value"
#define StatEventAppStart @"app-start"
#define StatParamAppVersion @"app-version"
#define StatParamAppPackage @"app-package"
#define StatParamPlatform @"platform"
#define StatParamOSName @"os-name"
#define StatParamOSEdition @"os-edition"
#define StatParamOSVersion @"os-version"
#define StatParamOSBits @"os-bits"
#define StatParamSPName @"sp-name"
#define StatParamSPVersion @"sp-version"
#define StatParamProcessorArchitect @"processor-architect"
#define StatParamProcessorCount @"processor-count"
#define StatParamProcessorName @"processor-name"
#define StatParamProcessorMHz @"processor-MHz"
#define StatParamDevice @"device"
#define StatParamModel @"model"
#define StatParamDeviceName @"device-name"
#define StatParamClientName @"client-name"

#define StatParamMemoryPhysicalMb @"memory-physical-Mb"
#define StatParamMemoryVirtualMb @"memory-virtual-Mb"
#define StatParamMemoryPagefileMb @"pagefile-Mb"
#define StatParamMemoryToalPagefileMb @"total-pagefile-Mb"

#define StatParamMonitorsCount @"monitors-count"
#define StatParamMonitorWidth @"monitor-%d-width"
#define StatParamMonitorHeight @"monitor-%d-height"

#define StatParamLanguageForNonUnicode @"language-for-non-unicode"
#define StatParamLocationISO3 @"location-ISO3"
#define StatParamLocationName @"location"
#define StatParamFormatsCountry @"formats-country"
#define StatParamLanguageUI @"language-UI"

#define StatEventAppFinish @"app-finish"
#define StatEventAppFailure @"app-failure"

#define StatEventWindowActivation @"window-activation"
#define StatEventWindowDeactivation @"window-deactivation"

#define StatEventSendingDataOff @"sending-data-off"

#define StatParamWindowCaption @"window-caption"
#define StatParamParentWindowCaption @"parent-window-caption"
#define StatParamWindowWidth @"window-width"
#define StatParamWindowHeight @"window-height"
#define StatParamTouchCoordinateX @"mouse-cursorX"
#define StatParamTouchCoordinateY @"mouse-cursorY"
#define StatParamScreenOrientation @"screen-orientation"

#define StatParamValueIOS @"iOS"

// Additional, new
#define StatEventFPS @"FPS"
#define StatEventUserProfile @"user-profile"
#define StatEventInAppPurchase @"purchase"

#define StatParamFPSMin @"min"
#define StatParamFPSMax @"max"
#define StatParamUserBirthday @"birthday"
#define StatParamUserAge @"age"
#define StatParamUserGender @"gender"
#define StatParamInAppPurchaseName @"name"
#define StatParamInAppPurchaseType @"type"
#define StatParamInAppPurchaseCost @"cost"
#define StatParamInAppPurchaseUserID @"user-id"
#define StatParamInAppPurchaseState @"state"
#define StatParamInAppPurchaseMarket @"market"
