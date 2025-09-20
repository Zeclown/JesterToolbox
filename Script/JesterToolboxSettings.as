UCLASS(Config = Game, DefaultConfig, Meta = (DisplayName = "Jester Toolbox Settings"))
class UJesterToolboxSettings : UDeveloperSettings
{
	UPROPERTY(EditAnywhere, Config, Category = "Assets")
	TSoftClassPtr<UAssetsLocatorService> AssetsLocatorServiceClass;
}