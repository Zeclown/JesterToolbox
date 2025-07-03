
#include "Core/ManagerLocatorSubsystem.h"

#include "JesterToolbox.h"

void UManagerLocatorSubsystem::RegisterActorManager(AActor* Manager)
{
#if !UE_BUILD_SHIPPING
	// Check and assert if the Manager is already registered
	for (AActor* ExistingManager : ActorManagers)
	{
		if (ExistingManager->GetClass() == Manager->GetClass())
		{
			UE_LOG(LogJesterToolbox, Error, TEXT("Manager %s is already registered!"), *Manager->GetName());
			return;
		}
	}
#endif
	ActorManagers.Add(Manager);
	Manager->OnDestroyed.RemoveAll(this);
	Manager->OnDestroyed.AddDynamic(this, &UManagerLocatorSubsystem::UnregisterActorManager);
}

void UManagerLocatorSubsystem::RegisterComponentManager(UActorComponent* Manager)
{
#if !UE_BUILD_SHIPPING
	// Check and assert if the Manager is already registered
	for (UActorComponent* ExistingManager : ComponentManagers)
	{
		if (ExistingManager->GetClass() == Manager->GetClass())
		{
			UE_LOG(LogJesterToolbox, Error, TEXT("Manager %s is already registered!"), *Manager->GetName());
			return;
		}
	}
#endif
	ComponentManagers.Add(Manager);
	Manager->GetOwner()->OnDestroyed.RemoveAll(this);
	Manager->GetOwner()->OnDestroyed.AddDynamic(this, &UManagerLocatorSubsystem::HandleComponentManagerOwnerDestroyed);
}

void UManagerLocatorSubsystem::UnregisterActorManager(AActor* Manager)
{
	if(Manager == nullptr)
	{
		return;
	}
	
	ActorManagers.Remove(Manager);
	// Unbind
	Manager->OnDestroyed.RemoveDynamic(this, &UManagerLocatorSubsystem::UnregisterActorManager);
}

void UManagerLocatorSubsystem::UnregisterComponentManager(UActorComponent* Manager)
{
	if(Manager == nullptr)
	{
		return;
	}
	
	ComponentManagers.Remove(Manager);
	// Unbind
	Manager->GetOwner()->OnDestroyed.RemoveDynamic(this, &UManagerLocatorSubsystem::HandleComponentManagerOwnerDestroyed);
}

UObject* UManagerLocatorSubsystem::GetManager(TSubclassOf<UObject> ManagerClass)
{
	if(ManagerClass == nullptr)
	{
		return nullptr;
	}

	if(ManagerClass->IsChildOf(AActor::StaticClass()))
	{
		for (AActor* Manager : ActorManagers)
		{
			if (Manager->GetClass()->IsChildOf(ManagerClass))
			{
				return Manager;
			}
		}
	}
	else if(ManagerClass->IsChildOf(UActorComponent::StaticClass()))
	{
		for (UActorComponent* Manager : ComponentManagers)
		{
			if (Manager->GetClass()->IsChildOf(ManagerClass))
			{
				return Manager;
			}
		}
	}
	UE_LOG(LogJesterToolbox, Error, TEXT("Manager of type %s not found!"), *ManagerClass->GetName());
	return nullptr;
}

void UManagerLocatorSubsystem::HandleComponentManagerOwnerDestroyed(AActor* Owner)
{
	TArray<UActorComponent*> ComponentsToRemove;
	for (UActorComponent* Manager : ComponentManagers)
	{
		if (Manager->GetOwner() == Owner)
		{
			ComponentsToRemove.Add(Manager);
		}
	}
}
