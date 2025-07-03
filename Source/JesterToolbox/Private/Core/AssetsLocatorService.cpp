// Fill out your copyright notice in the Description page of Project Settings.


#include "Core/AssetsLocatorService.h"

#include "GameplayTagContainer.h"

void UAssetsLocatorService::Initialize()
{
	if(bInitialized)
	{
		return;
	}

	// Flatten the arrays
	for (const auto& Category : RegisteredAssets)
	{
		for (const auto& Pair : Category.Value.Assets)
		{
			Assets.Add(Pair.Key, Pair.Value);
		}
		
		for (const auto& Pair : Category.Value.Classes)
		{
			Classes.Add(Pair.Key, Pair.Value);
		}
	}
	bInitialized = true;
}

UObject* UAssetsLocatorService::GetAsset(const FGameplayTag& Tag, const TSubclassOf<UObject>& ExpectedClass) const
{
	if (const auto Asset = Assets.Find(Tag))
	{
		checkf(ExpectedClass == nullptr || (*Asset)->GetClass()->IsChildOf(ExpectedClass),
			TEXT("Data asset with tag '%s' is not of expected type '%s'! Found: '%s'"),
			*Tag.ToString(), *ExpectedClass->GetName(), *(*Asset)->GetName());
		return *Asset;
	}
	
	checkf(false, TEXT("Data asset with tag '%s' not found in CultAssetsService!"), *Tag.ToString());
	return nullptr; // Not found
}

TSubclassOf<UObject> UAssetsLocatorService::GetAssetClass(const FGameplayTag& Tag, const TSubclassOf<UObject>& ExpectedClass) const
{
	if (const auto Asset = Classes.Find(Tag))
	{
		checkf(ExpectedClass == nullptr || Asset->Get()->IsChildOf(ExpectedClass),
		TEXT("Actor class with tag '%s' is not of expected type '%s'! Found: '%s'"),
		*Tag.ToString(), *ExpectedClass->GetName(), *Asset->Get()->GetName());
		return *Asset;
	}
	checkf(false, TEXT("Actor class with tag '%s' not found in CultAssetsService!"), *Tag.ToString());
	return nullptr; // Not found
}

TSoftObjectPtr<UWorld> UAssetsLocatorService::GetLevel(const FGameplayTag& Tag) const
{
	if(!ensureMsgf(RegisteredLevels.Contains(Tag), TEXT("Level with tag '%s' not found in CultAssetsService!"), *Tag.ToString()))
	{
		return nullptr;
	}
	
	return RegisteredLevels[Tag];
}

