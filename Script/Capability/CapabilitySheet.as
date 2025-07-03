class UCapabilitySheet_AS : UDataAsset
{
    UPROPERTY(EditAnywhere)
    TArray<TSubclassOf<UCapability_AS>> Capabilities;
}