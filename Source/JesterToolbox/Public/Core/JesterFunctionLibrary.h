// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "JesterFunctionLibrary.generated.h"

/**
 * 
 */
UCLASS()
class JESTERTOOLBOX_API UJesterFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static UManagerLocatorSubsystem* GetManagerLocator();

	UFUNCTION(Category="UI", BlueprintCallable, BlueprintPure)
	static FText TimeDurationToText(float TimeSeconds);

	UFUNCTION(BlueprintCallable, Category="Logs")
	static FString GetASCurrentFunctionName();

	UFUNCTION(ScriptCallable, Category="System")
	static void CopyToClipboard(FString ToCopy);

	UFUNCTION(ScriptCallable, Category="System", meta=(WorldContext="WorldContextObject"))
	static APlayerController* GetLocalPlayerController(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category="Math")
	static FRotator UnwindRotator(FRotator Rotator);

	UFUNCTION(BlueprintPure, Category="Math")
	static float UnwindDegrees(float Angle);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static TArray<UAnimMetaData*> GetMetaDataOfClass(UAnimationAsset* Animation, TSubclassOf<UAnimMetaData> MetaDataClass);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static FVector HitToDirection(FHitResult const& Hit);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static float EvaluateFromRuntimeCurve(FRuntimeFloatCurve const& Curve, float Time);
	
	UFUNCTION(BlueprintCallable)
	static void LogError(FString Message);

	UFUNCTION(BlueprintCallable)
	static FString GetLeafTag(FGameplayTag Tag);

	// Return a container of all the parents of the given tag explicitly, including the tag itself
	UFUNCTION(BlueprintCallable)
	static FGameplayTagContainer GetParentsTag(FGameplayTag Tag);
	
	UFUNCTION(BlueprintCallable)
	static TArray<FGameplayTag> GetTagNodes(FGameplayTagContainer Container, FGameplayTag Parent);
	
	UFUNCTION(Category="GameplayTags", BlueprintCallable)
	static FGameplayTagContainer GetAllChildTags(FGameplayTag Tag, int Depth, bool bOnlyLeafTags = false);

	UFUNCTION(BlueprintCallable, BlueprintPure)
	static bool IsFloatInBounds(float Value, FFloatRange Bounds);

	UFUNCTION(BlueprintCallable, BlueprintPure)
	static float PickRandomFloatInBounds(FFloatRange Bounds);

	UFUNCTION(BlueprintCallable, BlueprintPure)
	static float ClampFloatInBounds(float Value, FFloatRange Bounds);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static bool IsIntInBounds(int Value, FInt32Range Bounds);

	UFUNCTION(BlueprintCallable, BlueprintPure)
	static int PickRandomIntInBounds(FInt32Range Bounds);

	UFUNCTION(ScriptCallable, Category="Core", meta=(DeterminesOutputType="ClassToSpawn"))
	static AActor* SpawnActor(const TSubclassOf<AActor>& ClassToSpawn, const FVector& Location, const FRotator& Rotation = FRotator::ZeroRotator, ESpawnActorCollisionHandlingMethod SpawnActorCollisionHandling = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn, const FName& Name = NAME_None, bool bDeferredSpawn = false, ULevel* Level = nullptr);

	UFUNCTION(ScriptCallable, Category="Core")
	static AActor* FinishSpawningActor(AActor* Actor, FTransform Transform, ESpawnActorScaleMethod ScaleMethod = ESpawnActorScaleMethod::MultiplyWithRoot);
	
	UFUNCTION(BlueprintCallable, meta=(DeterminesOutputType="ToCopy"))
	static UObject* CopyObject(UObject* ToCopy);

	UFUNCTION(BlueprintCallable)
	static void CopyObjectTo(UObject* Source, UObject* Destination);
	
	template<typename T>
	static T* FindDefaultComponentByClass(const TSubclassOf<T> InActorClass)
	{
		return (T*)FindDefaultComponentByClass(InActorClass, T::StaticClass());
	}

	UFUNCTION(BlueprintCallable, meta=(DeterminesOutputType="ComponentClass"))
	static UActorComponent* FindDefaultComponentByClass(const TSubclassOf<UActorComponent> ComponentClass, const TSubclassOf<AActor> ActorClass);
	
	UFUNCTION(BlueprintCallable, meta=(DeterminesOutputType="ComponentClass"))
	static TArray<UActorComponent*> FindDefaultComponentsByClass(const TSubclassOf<UActorComponent> ComponentClass, const TSubclassOf<AActor> ActorClass);

	UFUNCTION(BlueprintCallable, BlueprintPure)
	static int GetObjectUniqueIDSafe(const UObject* Object);
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	static UInputComponent* GetInputComponent(AActor* Actor);

	UFUNCTION(BlueprintCallable, BlueprintPure,meta=(DeterminesOutputType="ObjectClass"))
	static UObject* GetDefaultObject(const TSubclassOf<UObject> ObjectClass);

	UFUNCTION(BlueprintCallable, Category="Debug", meta=(WorldContext="WorldContextObject"))
	static void DrawDebugCameraFromValues(const UObject* WorldContextObject, FVector const& Location, FRotator const& Rotation, float FOVDeg, float Scale = 1.f, FColor const& Color = FColor::White, bool bPersistentLines = false, float LifeTime = -1.f, uint8 DepthPriority = 0);

	UFUNCTION(ScriptCallable, Category="Math")
	static FVector MirrorVectorByNormal(FVector InVect, FVector InNormal);
	
	UFUNCTION(BlueprintCallable, Category = "Helpers")
	static bool CallFunctionByName(UObject* ObjPtr, FName FunctionName);
	
	UFUNCTION(BlueprintPure, meta=(WorldContext="WorldContextObject"))
	static UGameStateInitialization* GetGameStateInitializationComponent(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, Category = "Helpers", meta=(WorldContext="WorldContextObject",DelegateFunctionParam = "FunctionName", DelegateObjectParam = "Object", DelegateBindType = "FGameStateInitizationEvent" ))
	static void BindToGameStateInitializationStep(UObject* WorldContextObject, FGameplayTag State, UObject* Object, FName FunctionName, bool bIsPostState = false);
};
