// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/EngineSubsystem.h"
#include "GameplayTags.h"
#include "BaseClasses/ScriptEngineSubsystem.h"
#include "AssetsLocatorService.generated.h"

USTRUCT(BlueprintType)
struct FAssetCategory
{
	GENERATED_BODY()
	
	UPROPERTY(EditDefaultsOnly, meta=(Categories = "Asset.Data", ForceInlineRow))
	TMap<FGameplayTag, UObject*> Assets;

	UPROPERTY(EditDefaultsOnly, meta=(Categories = "Asset.Class", ForceInlineRow))
	TMap<FGameplayTag, TSubclassOf<UObject>> Classes;
};

/**
 * 
 */
UCLASS(Abstract, Blueprintable, BlueprintType)
class JESTERTOOLBOX_API UAssetsLocatorService : public UObject
{
	GENERATED_BODY()

public:
	virtual void Initialize();
	
	UFUNCTION(BlueprintPure, meta=(DeterminesOutputType = "ExpectedClass", AutoCreateRefTerm="Tag"))
	UObject* GetAsset(const FGameplayTag& Tag, const TSubclassOf<UObject>& ExpectedClass = nullptr) const;

	UFUNCTION(BlueprintPure, meta=(DeterminesOutputType = "ExpectedClass", AutoCreateRefTerm="Tag"))
	TSubclassOf<UObject> GetAssetClass(const FGameplayTag& Tag, const TSubclassOf<UObject>& ExpectedClass = nullptr) const;
	
	UFUNCTION(BlueprintPure, meta=(AutoCreateRefTerm="Tag"))
	TSoftObjectPtr<UWorld> GetLevel(const FGameplayTag& Tag) const;
	
protected:
	// Split in categories to organize assets better but they are meaningless, will get flattened in the end
	UPROPERTY(EditDefaultsOnly)
	TMap<FString, FAssetCategory> RegisteredAssets;
	UPROPERTY(EditDefaultsOnly, meta=(Categories = "Asset.Level", ForceInlineRow))
	TMap<FGameplayTag, TSoftObjectPtr<UWorld>> RegisteredLevels;
	
	UPROPERTY(meta=(ForceInlineRow))
	TMap<FGameplayTag, UObject*> Assets;
	UPROPERTY(meta=(ForceInlineRow))
	TMap<FGameplayTag, TSubclassOf<UObject>> Classes;

	bool bInitialized;
};
