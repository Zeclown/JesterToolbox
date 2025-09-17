// Copyright Epic Games, Inc. All Rights Reserved.

#include "JesterToolbox.h"

#include "AngelscriptCodeModule.h"
#include "Core/ManagerActor.h"
#include "Core/ManagerActorComponent.h"
#include "Preprocessor/AngelscriptPreprocessor.h"

DEFINE_LOG_CATEGORY(LogJesterToolbox);

#define LOCTEXT_NAMESPACE "FJesterToolboxModule"

void FJesterToolboxModule::StartupModule()
{
	// This code will execute after your module is loaded into memory; the exact timing is specified in the .uplugin file per-module
	
	FAngelscriptCodeModule::GetClassAnalyze().BindLambda([](FString& GeneratedCode, TSharedPtr<struct FAngelscriptClassDesc> ClassDesc, bool& bHasStatics)
	{
		if (ClassDesc->CodeSuperClass->IsChildOf(UManagerActorComponent::StaticClass()))
		{
			GeneratedCode += FString::Printf(
				TEXT("\n %s Get() __generated {")
				TEXT("return Cast<%s>(UManagerLocatorSubsystem::Get().GetManager(%s));")
				TEXT("}"),
				*ClassDesc->ClassName,
				*ClassDesc->ClassName,
				*ClassDesc->ClassName
			);
			
			bHasStatics = true;
		}
		else if(ClassDesc->CodeSuperClass->IsChildOf(AManagerActor::StaticClass()))
		{
			GeneratedCode += FString::Printf(
			TEXT("\n %s Get() __generated {")
			TEXT("return Cast<%s>(UManagerLocatorSubsystem::Get().GetManager(%s));")
			TEXT("}"),
			*ClassDesc->ClassName,
			*ClassDesc->ClassName,
			*ClassDesc->ClassName
		);
			bHasStatics = true;
		}
	});
}

void FJesterToolboxModule::ShutdownModule()
{
	// This function may be called during shutdown to clean up your module.  For modules that support dynamic reloading,
	// we call this function before unloading the module.
}

#undef LOCTEXT_NAMESPACE
	
IMPLEMENT_MODULE(FJesterToolboxModule, JesterToolbox)