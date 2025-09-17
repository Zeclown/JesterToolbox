// Fill out your copyright notice in the Description page of Project Settings.
#include "Core/ManagerActor.h"

#include "Core/ManagerLocatorSubsystem.h"

void AManagerActor::BeginPlay()
{
	Super::BeginPlay();
	
	if (UEngine* Engine = GEngine)
	{
		if (UManagerLocatorSubsystem* ManagerLocator = Engine->GetEngineSubsystem<UManagerLocatorSubsystem>())
		{
			ManagerLocator->RegisterActorManager(this);
		}
	}
}

void AManagerActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);

	if(UEngine* Engine = GEngine)
	{
		if (UManagerLocatorSubsystem* ManagerLocator = Engine->GetEngineSubsystem<UManagerLocatorSubsystem>())
		{
			ManagerLocator->UnregisterActorManager(this);
		}
	}
}
