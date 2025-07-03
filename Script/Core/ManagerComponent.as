// Simple component to register with the ViceManagerLocator
UCLASS(Abstract)
class UManagerComponent_AS :UActorComponent
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Jester::GetManagerLocator().RegisterComponentManager(this);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        Jester::GetManagerLocator().UnregisterComponentManager(this);
    }
}