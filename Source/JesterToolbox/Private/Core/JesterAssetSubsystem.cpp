// Fill out your copyright notice in the Description page of Project Settings.

#include "Core/JesterAssetSubsystem.h"
#include "JesterToolbox.h"
#include "Engine/DeveloperSettings.h"

void UJesterAssetSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);

	// Try to get JesterToolboxSettings first
	UClass* JesterSettingsClass = FindObject<UClass>(ANY_PACKAGE, TEXT("UJesterToolboxSettings"));
	if (JesterSettingsClass)
	{
		const UObject* Settings = JesterSettingsClass->GetDefaultObject();
		if (Settings)
		{
			// Use reflection to get the AssetsLocatorServiceClass property
			FProperty* Property = JesterSettingsClass->FindPropertyByName(TEXT("AssetsLocatorServiceClass"));
			if (Property)
			{
				const FSoftClassProperty* SoftClassProperty = CastField<FSoftClassProperty>(Property);
				if (SoftClassProperty)
				{
					const TSoftClassPtr<UAssetsLocatorService>* ServiceClassPtr =
						SoftClassProperty->ContainerPtrToValuePtr<TSoftClassPtr<UAssetsLocatorService>>(Settings);

					if (ServiceClassPtr && !ServiceClassPtr->IsNull())
					{
						TSubclassOf<UAssetsLocatorService> ClassToUse = ServiceClassPtr->LoadSynchronous();
						if (ClassToUse)
						{
							AssetsLocatorService = NewObject<UAssetsLocatorService>(this, ClassToUse);
							if (AssetsLocatorService)
							{
								AssetsLocatorService->Initialize();
								UE_LOG(LogJesterToolbox, Log, TEXT("JesterAssetSubsystem initialized AssetsLocatorService: %s"),
									*ClassToUse->GetName());
								return;
							}
						}
					}
				}
			}
		}
	}

	// Fallback: Check project-specific developer settings (like SpellRaveDeveloperSettings)
	for (TObjectIterator<UClass> It; It; ++It)
	{
		UClass* SettingsClass = *It;
		if (SettingsClass && SettingsClass->IsChildOf(UDeveloperSettings::StaticClass()) &&
			SettingsClass != JesterSettingsClass) // Skip JesterToolboxSettings since we already checked it
		{
			const UObject* Settings = SettingsClass->GetDefaultObject();
			if (Settings)
			{
				FProperty* Property = SettingsClass->FindPropertyByName(TEXT("AssetsLocatorServiceClass"));
				if (Property)
				{
					const FSoftClassProperty* SoftClassProperty = CastField<FSoftClassProperty>(Property);
					if (SoftClassProperty)
					{
						const TSoftClassPtr<UAssetsLocatorService>* ServiceClassPtr =
							SoftClassProperty->ContainerPtrToValuePtr<TSoftClassPtr<UAssetsLocatorService>>(Settings);

						if (ServiceClassPtr && !ServiceClassPtr->IsNull())
						{
							TSubclassOf<UAssetsLocatorService> ClassToUse = ServiceClassPtr->LoadSynchronous();
							if (ClassToUse)
							{
								AssetsLocatorService = NewObject<UAssetsLocatorService>(this, ClassToUse);
								if (AssetsLocatorService)
								{
									AssetsLocatorService->Initialize();
									UE_LOG(LogJesterToolbox, Log, TEXT("JesterAssetSubsystem initialized AssetsLocatorService from %s: %s"),
										*SettingsClass->GetName(), *ClassToUse->GetName());
									return;
								}
							}
						}
					}
				}
			}
		}
	}

	if (!AssetsLocatorService)
	{
		UE_LOG(LogJesterToolbox, Warning, TEXT("JesterAssetSubsystem could not initialize AssetsLocatorService. Configure it in JesterToolboxSettings or project developer settings."));
	}
}