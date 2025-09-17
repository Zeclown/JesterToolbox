// Fill out your copyright notice in the Description page of Project Settings.


#include "Core/JesterFunctionLibrary.h"

#include "AngelscriptCodeModule.h"
#include "AngelscriptManager.h"
#include "GameplayTagContainer.h"
#include "GameplayTagsManager.h"
#include "Animation/AnimMetaData.h"
#include "Core/GameStateInitialization.h"
#include "Engine/SCS_Node.h"
#include "Engine/SimpleConstructionScript.h"
#include "GameFramework/GameStateBase.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetMathLibrary.h"
#if PLATFORM_WINDOWS
#include "Windows/WindowsPlatformApplicationMisc.h"
#endif


UManagerLocatorSubsystem* UJesterFunctionLibrary::GetManagerLocator()
{
	return GEngine->GetEngineSubsystem<UManagerLocatorSubsystem>();
}

FText UJesterFunctionLibrary::TimeDurationToText(float TimeSeconds)
{
	FText TimeText;
	// Returns time in the format HH:MM:SS, or MM:SS if less than an hour
	int32 Hours = FMath::FloorToInt(TimeSeconds / 3600.f);
	int32 Minutes = FMath::FloorToInt((TimeSeconds - (Hours * 3600.f)) / 60.f);
	int32 Seconds = FMath::FloorToInt(TimeSeconds - (Hours * 3600.f) - (Minutes * 60.f));
	if (Hours > 0)
	{
		TimeText = FText::FromString(FString::Printf(TEXT("%02d:%02d:%02d"), Hours, Minutes, Seconds));
	}
	else
	{
		TimeText = FText::FromString(FString::Printf(TEXT("%02d:%02d"), Minutes, Seconds));
	}
	return TimeText;
}

FString UJesterFunctionLibrary::GetASCurrentFunctionName()
{
	TArray<FString> Stack = FAngelscriptManager::GetAngelscriptCallstack();
	// Find from last, the first occurence of a | Line
	for (int32 Index = Stack.Num() - 1; Index >= 0; --Index)
	{
		if (Stack[Index].Contains(TEXT("| Line")))
		{
			// Remove | Line X | Col X from the end of string
			int ToRemove = Stack[Index].Len() - Stack[Index].Find(TEXT("| Line"));
			return Stack[Index].Left(Stack[Index].Len() - ToRemove).TrimStart().TrimEnd();
		}
	}
	return FString();
}

void UJesterFunctionLibrary::CopyToClipboard(FString ToCopy)
{
#if PLATFORM_WINDOWS
	// Copy the FString to clipboard
	FPlatformApplicationMisc::ClipboardCopy(*ToCopy);
#endif
}

APlayerController* UJesterFunctionLibrary::GetLocalPlayerController(UObject* WorldContextObject)
{
	return UGameplayStatics::GetPlayerController(WorldContextObject, 0);
}

FRotator UJesterFunctionLibrary::UnwindRotator(FRotator Rotator)
{
	FRotator UnwoundRotator = Rotator;
	UnwoundRotator.Pitch = FMath::UnwindDegrees(UnwoundRotator.Pitch);
	UnwoundRotator.Yaw = FMath::UnwindDegrees(UnwoundRotator.Yaw);
	UnwoundRotator.Roll = FMath::UnwindDegrees(UnwoundRotator.Roll);
	return UnwoundRotator;
}

float UJesterFunctionLibrary::UnwindDegrees(float Angle)
{
	return FMath::UnwindDegrees(Angle);
}

TArray<UAnimMetaData*> UJesterFunctionLibrary::GetMetaDataOfClass(UAnimationAsset* Animation, TSubclassOf<UAnimMetaData> MetaDataClass)
{
	TArray<UAnimMetaData*> MetaDataOfClass;
	if (Animation)
	{
		for (UAnimMetaData* MetaData : Animation->GetMetaData())
		{
			if (MetaData->GetClass()->IsChildOf(MetaDataClass))
			{
				MetaDataOfClass.Add(MetaData);
			}
		}
	}
	return MetaDataOfClass;
}

FVector UJesterFunctionLibrary::HitToDirection(FHitResult const& Hit)
{
	return (Hit.TraceEnd - Hit.TraceStart).GetSafeNormal();
}

float UJesterFunctionLibrary::EvaluateFromRuntimeCurve(FRuntimeFloatCurve const& Curve, float Time)
{
	return Curve.GetRichCurveConst()->Eval(Time);
}

float UJesterFunctionLibrary::PickRandomFloatInBounds(FFloatRange Bounds)
{
	float Min = 0;
	if(Bounds.GetLowerBound().IsOpen())
	{
		Min = FLT_MIN;
	}
	else if(Bounds.GetLowerBound().IsExclusive())
	{
		Min = Bounds.GetLowerBoundValue() + FLT_EPSILON;
	}
	else
	{
		Min = Bounds.GetLowerBoundValue();
	}
	
	float Max = 0;
	if(Bounds.GetUpperBound().IsOpen())
	{
		Max = FLT_MAX;
	}
	else if(Bounds.GetUpperBound().IsExclusive())
	{
		Max = Bounds.GetUpperBoundValue() - FLT_EPSILON;
	}
	else
	{
		Max = Bounds.GetUpperBoundValue();
	}

	return FMath::RandRange(Min, Max);
}

float UJesterFunctionLibrary::ClampFloatInBounds(float Value, FFloatRange Bounds)
{
	float Min = 0;
	if(Bounds.GetLowerBound().IsOpen())
	{
		Min = FLT_MIN;
	}
	else if(Bounds.GetLowerBound().IsExclusive())
	{
		Min = Bounds.GetLowerBoundValue() + FLT_EPSILON;
	}
	else
	{
		Min = Bounds.GetLowerBoundValue();
	}

	float Max = 0;
	if(Bounds.GetUpperBound().IsOpen())
	{
		Max = FLT_MAX;
	}
	else if(Bounds.GetUpperBound().IsExclusive())
	{
		Max = Bounds.GetUpperBoundValue() - FLT_EPSILON;
	}
	else
	{
		Max = Bounds.GetUpperBoundValue();
	}
	return FMath::Clamp(Value, Min, Max);
}

void UJesterFunctionLibrary::LogError(FString Message)
{
	UKismetSystemLibrary::PrintString(GEngine->GetWorld(), Message, true, true, FLinearColor::Red, 5.0f);
}

FString UJesterFunctionLibrary::GetLeafTag(FGameplayTag Tag)
{
	FString TagString = Tag.ToString();
	int32 Index = TagString.Find(TEXT("."), ESearchCase::CaseSensitive, ESearchDir::FromEnd);
	if(Index != INDEX_NONE)
	{
		return TagString.RightChop(Index + 1);
	}
	return TagString;
}

FGameplayTagContainer UJesterFunctionLibrary::GetParentsTag(FGameplayTag Tag)
{
	return Tag.GetGameplayTagParents();
}

TArray<FGameplayTag> UJesterFunctionLibrary::GetTagNodes(FGameplayTagContainer Container, FGameplayTag Parent)
{
	// Get all tag in container matching the parent
	TArray<FGameplayTag> Tags;
	for(int i = 0; i < Container.Num(); i++)
	{
		if(Container.GetByIndex(i).MatchesTag(Parent))
		{
			Tags.Add(Container.GetByIndex(i));
		}
	}
	return Tags;
}

namespace 
{
	void GetAllChildTagsRecursive(FGameplayTag Tag, TSharedPtr<FGameplayTagNode> CurrentNode, int CurrentDepth, int MaxDepth, bool bOnlyLeafs, FGameplayTagContainer& OutTags)
	{
		for(int i = 0; i < CurrentNode->GetChildTagNodes().Num(); i++)
		{
			if(!bOnlyLeafs || CurrentNode->GetChildTagNodes()[i]->GetChildTagNodes().IsEmpty())
			{
				OutTags.AddTag(CurrentNode->GetChildTagNodes()[i]->GetCompleteTag());
			}
			if (CurrentDepth < MaxDepth)
			{
				GetAllChildTagsRecursive(Tag, CurrentNode->GetChildTagNodes()[i], CurrentDepth + 1, MaxDepth, bOnlyLeafs, OutTags);
			}
		}
	}
}

FGameplayTagContainer UJesterFunctionLibrary::GetAllChildTags(FGameplayTag Tag, int Depth, bool bOnlyLeafTags)
{
	const UGameplayTagsManager& TagsManager = UGameplayTagsManager::Get();
	FGameplayTagContainer TagContainer;

	TSharedPtr<FGameplayTagNode> GameplayTagNode = TagsManager.FindTagNode(Tag);
	if (GameplayTagNode.IsValid())
	{
		GetAllChildTagsRecursive(Tag, GameplayTagNode, 0, Depth, bOnlyLeafTags, TagContainer);
	}
	return TagContainer;
}

bool UJesterFunctionLibrary::IsFloatInBounds(float Value, FFloatRange Bounds)
{
	return Bounds.Contains(Value);
}

bool UJesterFunctionLibrary::IsIntInBounds(int Value, FInt32Range Bounds)
{
	return Bounds.Contains(Value);
}

int UJesterFunctionLibrary::PickRandomIntInBounds(FInt32Range Bounds)
{
	int32 Min = 0;
	if(Bounds.GetLowerBound().IsOpen())
	{
		Min = FLT_MIN;
	}
	else if(Bounds.GetLowerBound().IsExclusive())
	{
		Min = Bounds.GetLowerBoundValue() + 1;
	}
	else
	{
		Min = Bounds.GetLowerBoundValue();
	}
	
	int32 Max = 0;
	if(Bounds.GetUpperBound().IsOpen())
	{
		Max = INT32_MAX;
	}
	else if(Bounds.GetUpperBound().IsExclusive())
	{
		Max = Bounds.GetUpperBoundValue() - 1;
	}
	else
	{
		Max = Bounds.GetUpperBoundValue();
	}

	return FMath::RandRange(Min, Max);
}

AActor* UJesterFunctionLibrary::SpawnActor(const TSubclassOf<AActor>& ClassToSpawn, const FVector& Location, const FRotator& Rotation, ESpawnActorCollisionHandlingMethod SpawnActorCollisionHandling, const FName& Name, bool bDeferredSpawn, ULevel* Level)
{
	UObject* WorldContext = FAngelscriptManager::CurrentWorldContext;
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContext, EGetWorldErrorMode::ReturnNull);
	if (World == nullptr)
	{
		FAngelscriptManager::Throw("Invalid World Context");
		return nullptr;
	}

	if (ClassToSpawn == nullptr)
	{
		FAngelscriptManager::Throw("Class was nullptr.");
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.Name = Name;
	Params.NameMode = FActorSpawnParameters::ESpawnActorNameMode::Requested;
	Params.bDeferConstruction = bDeferredSpawn;
	Params.SpawnCollisionHandlingOverride = SpawnActorCollisionHandling;

	if (Level != nullptr)
	{
		Params.OverrideLevel = Level;
	}
	else if (World->IsGameWorld() && FAngelscriptCodeModule::GetDynamicSpawnLevel().IsBound())
	{
		Params.OverrideLevel = FAngelscriptCodeModule::GetDynamicSpawnLevel().Execute();
	}
	else if (auto* Comp = Cast<UActorComponent>(WorldContext))
	{
		Params.OverrideLevel = Comp->GetOwner() ? Comp->GetOwner()->GetLevel() : nullptr;
	}
	else if (auto* Actor = Cast<AActor>(WorldContext))
	{
		Params.OverrideLevel = Actor->GetLevel();
	}

	return World->SpawnActor(ClassToSpawn, &Location, &Rotation, Params);
}

AActor* UJesterFunctionLibrary::FinishSpawningActor(AActor* Actor, FTransform Transform, ESpawnActorScaleMethod ScaleMethod)
{
	return UGameplayStatics::FinishSpawningActor(Actor, Transform, ScaleMethod);
}

UObject* UJesterFunctionLibrary::CopyObject(UObject* ToCopy)
{
	if(ToCopy == nullptr)
	{
		return nullptr;
	}
	
	return DuplicateObject(ToCopy, ToCopy->GetOuter());
}

void UJesterFunctionLibrary::CopyObjectTo(UObject* Source, UObject* Destination)
{
	if(Source == nullptr || Destination == nullptr)
	{
		return;
	}
	
	// Copy the properties from Source to Destination
	FObjectDuplicationParameters DuplicationParams(Source, Destination);
	DuplicationParams.DuplicateMode = EDuplicateMode::Normal;

	UObject* DuplicatedObject = StaticDuplicateObjectEx(DuplicationParams);
	if (DuplicatedObject)
	{
		Destination->MarkPackageDirty();
	}
}

UActorComponent* UJesterFunctionLibrary::FindDefaultComponentByClass(const TSubclassOf<UActorComponent> InComponentClass, const TSubclassOf<AActor> InActorClass)
{
	if (!IsValid(InActorClass))
	{
		return nullptr;
	}

	// Check CDO.
	AActor* ActorCDO = InActorClass->GetDefaultObject<AActor>();
	UActorComponent* FoundComponent = ActorCDO->FindComponentByClass(InComponentClass);

	if (FoundComponent != nullptr)
	{
		return FoundComponent;
	}

	// Check blueprint nodes. Components added in blueprint editor only (and not in code) are not available from
	// CDO.
	UBlueprintGeneratedClass* RootBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(InActorClass);
	UClass* ActorClass = InActorClass;

	// Go down the inheritance tree to find nodes that were added to parent blueprints of our blueprint graph.
	do
	{
		UBlueprintGeneratedClass* ActorBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(ActorClass);
		if (!ActorBlueprintGeneratedClass)
		{
			return nullptr;
		}

		const TArray<USCS_Node*>& ActorBlueprintNodes =
			ActorBlueprintGeneratedClass->SimpleConstructionScript->GetAllNodes();

		for (USCS_Node* Node : ActorBlueprintNodes)
		{
			if (Node->ComponentClass->IsChildOf(InComponentClass))
			{
				return Node->GetActualComponentTemplate(RootBlueprintGeneratedClass);
			}
		}

		ActorClass = Cast<UClass>(ActorClass->GetSuperStruct());

	} while (ActorClass != AActor::StaticClass());

	return nullptr;
}

TArray<UActorComponent*> UJesterFunctionLibrary::FindDefaultComponentsByClass(const TSubclassOf<UActorComponent> InComponentClass, const TSubclassOf<AActor> InActorClass)
{
	if (!IsValid(InActorClass))
	{
		return TArray<UActorComponent*>();
	}

	// Check CDO.
	AActor* ActorCDO = InActorClass->GetDefaultObject<AActor>();
	TArray<UActorComponent*> ComponentsFound = ActorCDO->K2_GetComponentsByClass(InComponentClass);

	// Check blueprint nodes. Components added in blueprint editor only (and not in code) are not available from
	// CDO.
	UBlueprintGeneratedClass* RootBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(InActorClass);
	UClass* ActorClass = InActorClass;

	// Go down the inheritance tree to find nodes that were added to parent blueprints of our blueprint graph.
	do
	{
		UBlueprintGeneratedClass* ActorBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(ActorClass);
		if (!ActorBlueprintGeneratedClass)
		{
			return ComponentsFound;
		}

		const TArray<USCS_Node*>& ActorBlueprintNodes =
			ActorBlueprintGeneratedClass->SimpleConstructionScript->GetAllNodes();

		for (USCS_Node* Node : ActorBlueprintNodes)
		{
			if (Node->ComponentClass->IsChildOf(InComponentClass))
			{
				ComponentsFound.AddUnique( Node->GetActualComponentTemplate(RootBlueprintGeneratedClass));
			}
		}

		ActorClass = Cast<UClass>(ActorClass->GetSuperStruct());

	} while (ActorClass != AActor::StaticClass());
	
	return ComponentsFound;
}

int UJesterFunctionLibrary::GetObjectUniqueIDSafe(const UObject* Object)
{
	if (!Object)
	{
		return 0;
	}
	
	return Object->GetUniqueID();
}

UInputComponent* UJesterFunctionLibrary::GetInputComponent(AActor* Actor)
{
	return Actor ? Actor->InputComponent : nullptr;
}

UObject* UJesterFunctionLibrary::GetDefaultObject(const TSubclassOf<UObject> ObjectClass)
{
	if(ObjectClass == nullptr)
	{
		return nullptr;
	}
	return ObjectClass->GetDefaultObject();
}

void UJesterFunctionLibrary::DrawDebugCameraFromValues(const UObject* WorldContextObject, FVector const& Location, FRotator const& Rotation, float FOVDeg, float Scale, FColor const& Color, bool bPersistentLines, float LifeTime, uint8 DepthPriority)
{
	DrawDebugCamera(WorldContextObject->GetWorld(), Location, Rotation, FOVDeg, Scale, Color, bPersistentLines, LifeTime, DepthPriority);
}

FVector UJesterFunctionLibrary::MirrorVectorByNormal(FVector InVect, FVector InNormal)
{
	return UKismetMathLibrary::MirrorVectorByNormal(InVect, InNormal);
}

bool UJesterFunctionLibrary::CallFunctionByName(UObject* ObjPtr, FName FunctionName)
{
	if (ObjPtr)
	{
		if (UFunction* Function = ObjPtr->FindFunction(FunctionName))
		{
			ObjPtr->ProcessEvent(Function, nullptr);
			return true;
		}
		return false;
	}
	return false;
}

UGameStateInitialization* UJesterFunctionLibrary::GetGameStateInitializationComponent(UObject* WorldContextObject)
{
	AGameStateBase* GameState = UGameplayStatics::GetGameState(WorldContextObject);
	if(GameState == nullptr)
	{
		return nullptr;
	}
	return GameState->FindComponentByClass<UGameStateInitialization>();
}

void UJesterFunctionLibrary::BindToGameStateInitializationStep(UObject* WorldContextObject, FGameplayTag State, UObject* Object, FName FunctionName, bool bIsPostState)
{
	UGameStateInitialization* InitComp = GetGameStateInitializationComponent(WorldContextObject);
	if(InitComp == nullptr)
	{
		FAngelscriptManager::Throw("GameStateInitialization component not found on GameState");
		return;
	}
	InitComp->BindToInitializationStep(State, Object, FunctionName, bIsPostState);
}
