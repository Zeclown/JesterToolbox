// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "JesterFunctionLibrary.h"
#include "ManagerActorComponent.h"
#include "GameStateInitialization.generated.h"

USTRUCT()
struct FGameStateInitializationEvent
{
	GENERATED_BODY()

	UPROPERTY()
	FGameplayTag State = FGameplayTag::EmptyTag;
	UPROPERTY()
	UObject* Object = nullptr;
	UPROPERTY()
	FName FunctionName = NAME_None;
	// Some events are post-state, meaning they should be called after the state is set instead of when we are entering it
	UPROPERTY()
	bool bIsPostState = false;
	
	FGameStateInitializationEvent() = default;
	FGameStateInitializationEvent(FGameplayTag InState, UObject* InObject, FName InFunctionName, bool bInIsPostState)
		: State(InState), Object(InObject), FunctionName(InFunctionName), bIsPostState(bInIsPostState)
	{
	}

	void Execute()
	{
		if(IsValid(Object) && !Object->IsUnreachable())
		{
			UJesterFunctionLibrary::CallFunctionByName(Object, FunctionName);
		}
	}
};

/**
 * Component that manages game state initialization steps.
 * It allows binding to specific initialization steps and triggers events when those steps are reached.
 * Meant to be inherited by a class that defines IsStepReadyToAdvance() to control the flow of initialization.
 */
UCLASS(Abstract, Blueprintable)
class JESTERTOOLBOX_API UGameStateInitialization : public UActorComponent
{
	GENERATED_BODY()

public:
	DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FGameStateInitizationEvent, FGameplayTag, NewInitializationState);
	UPROPERTY(BlueprintAssignable)
	FGameStateInitizationEvent OnGameStateInitializationChanged;
	UPROPERTY(BlueprintAssignable)
	FGameStateInitizationEvent OnGameStateFullyInitialized;
	
	UGameStateInitialization();

	bool IsStateAlreadyInitialized(FGameplayTag State) const;
	bool IsCurrentState(FGameplayTag State) const;
	
	virtual void BeginPlay() override;
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
	
	UFUNCTION(ScriptCallable, Category = "Flow", meta = (DelegateFunctionParam = "FunctionName", DelegateObjectParam = "Object", DelegateBindType = "FGameStateInitizationEvent"))
	void BindToInitializationStep(FGameplayTag State, UObject* Object, FName FunctionName, bool bIsPostState = false);

	UFUNCTION(BlueprintImplementableEvent)
	bool IsStepReadyToAdvance(FGameplayTag CurrentStep) const;

	
protected:
	UPROPERTY(BlueprintReadWrite, meta=(Categories = "GameStateInitialization"))
	TArray<FGameplayTag> OrderedInitializationSteps;
	
	TArray<FGameStateInitializationEvent> InitializationEvents;
	int InitializationIndex = 0;
};
