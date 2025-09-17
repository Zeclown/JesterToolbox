// Fill out your copyright notice in the Description page of Project Settings.
#include "Core/ManagerActorComponent.h"

#include "Core/ManagerLocatorSubsystem.h"

void UManagerActorComponent::BeginPlay()
{
	Super::BeginPlay();
	if (UEngine* Engine = GEngine)
	{
		if (UManagerLocatorSubsystem* ManagerLocator = Engine->GetEngineSubsystem<UManagerLocatorSubsystem>())
		{
			ManagerLocator->RegisterComponentManager(this);
		}
	}
}

void UManagerActorComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	if (UEngine* Engine = GEngine)
	{
		if (UManagerLocatorSubsystem* ManagerLocator = Engine->GetEngineSubsystem<UManagerLocatorSubsystem>())
		{
			ManagerLocator->UnregisterComponentManager(this);
		}
	}
}
