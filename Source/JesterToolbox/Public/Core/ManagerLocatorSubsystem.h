﻿// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "ManagerLocatorSubsystem.generated.h"

/**
 * 
 */
UCLASS()
class JESTERTOOLBOX_API UManagerLocatorSubsystem : public UEngineSubsystem
{
	GENERATED_BODY()
	
public:
	UFUNCTION(BlueprintCallable, Category = "Vice|ManagerLocator")
	void RegisterActorManager(AActor* Manager);

	UFUNCTION(BlueprintCallable, Category = "Vice|ManagerLocator")
	void RegisterComponentManager(UActorComponent* Manager);

	UFUNCTION(BlueprintCallable, Category = "Vice|ManagerLocator")
	void UnregisterActorManager(AActor* Manager);

	UFUNCTION(BlueprintCallable, Category = "Vice|ManagerLocator")
	void UnregisterComponentManager(UActorComponent* Manager);
	
	UFUNCTION(BlueprintPure, Category = "Vice|ManagerLocator", meta=(DeterminesOutputType = "ManagerClass"))
	UObject* GetManager(TSubclassOf<UObject> ManagerClass);

private:
	UFUNCTION()
	void HandleComponentManagerOwnerDestroyed(AActor* Owner);
	
	UPROPERTY()
	TArray<AActor*> ActorManagers;

	UPROPERTY()
	TArray<UActorComponent*> ComponentManagers;
};
