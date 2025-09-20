// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AssetsLocatorService.h"
#include "Subsystems/EngineSubsystem.h"
#include "JesterAssetSubsystem.generated.h"

/**
 * Engine subsystem that manages the AssetsLocatorService
 * Automatically initializes the service on engine startup
 */
UCLASS()
class JESTERTOOLBOX_API UJesterAssetSubsystem : public UEngineSubsystem
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, Category = "Jester|Assets")
	UAssetsLocatorService* GetAssetsLocatorService() const { return AssetsLocatorService; }

	virtual void Initialize(FSubsystemCollectionBase& Collection) override;

private:
	UPROPERTY()
	UAssetsLocatorService* AssetsLocatorService = nullptr;
};