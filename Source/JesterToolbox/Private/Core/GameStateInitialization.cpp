// Fill out your copyright notice in the Description page of Project Settings.


#include "Core/GameStateInitialization.h"

#include "JesterToolbox.h"


// Sets default values for this component's properties
UGameStateInitialization::UGameStateInitialization()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}

// Called when the game starts
void UGameStateInitialization::BeginPlay()
{
	Super::BeginPlay();
	
	InitializationIndex = 0;
}

bool UGameStateInitialization::IsStateAlreadyInitialized(FGameplayTag State) const
{
	return OrderedInitializationSteps.Find(State) < InitializationIndex;
}

bool UGameStateInitialization::IsCurrentState(FGameplayTag State) const
{
	return OrderedInitializationSteps.IsValidIndex(InitializationIndex) && OrderedInitializationSteps[InitializationIndex] == State;
}




// Called every frame
void UGameStateInitialization::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if(InitializationIndex >= OrderedInitializationSteps.Num())
	{
		return;
	}

	// Go through the initialization steps in order, only change steps once per frame
	if(IsStepReadyToAdvance(OrderedInitializationSteps[InitializationIndex]))
	{
		UE_LOG(LogJesterToolbox, Log, TEXT("GameState Initialization Complete: %s"), *OrderedInitializationSteps[InitializationIndex].ToString());
		InitializationIndex++;
		if(OrderedInitializationSteps.IsValidIndex(InitializationIndex))
		{
			TArray<int> TriggeredEvents;
			// Call initialization events and clean them up
			for(int i = 0; i < InitializationEvents.Num(); ++i)
			{
				FGameStateInitializationEvent& Event = InitializationEvents[i];
				const int EventStateIdx = OrderedInitializationSteps.Find(Event.State);
				if(EventStateIdx == InitializationIndex && !Event.bIsPostState )
				{
					Event.Execute();
					TriggeredEvents.Add(i);
				}
				else if(Event.bIsPostState && EventStateIdx < InitializationIndex)
				{
					Event.Execute();
					TriggeredEvents.Add(i);
				}
			}
			
			for(int i = TriggeredEvents.Num() - 1; i >= 0; --i)
			{
				InitializationEvents.RemoveAt(TriggeredEvents[i]);
			}
			
			OnGameStateInitializationChanged.Broadcast(OrderedInitializationSteps[InitializationIndex]);
		}
		else
		{
			// Trigger last initialization events
			for(FGameStateInitializationEvent& Event : InitializationEvents)
			{
				if(Event.State == OrderedInitializationSteps.Last())
				{
					Event.Execute();
				}
			}
			OnGameStateFullyInitialized.Broadcast(FGameplayTag::EmptyTag);
			// No more steps, disable ticking
			SetComponentTickEnabled(false);
		}
	}
}

void UGameStateInitialization::BindToInitializationStep(FGameplayTag State, UObject* Object, FName FunctionName, bool bIsPostState)
{
	FGameStateInitializationEvent NewEvent = FGameStateInitializationEvent(State, Object, FunctionName, bIsPostState);
	if(IsStateAlreadyInitialized(State) || (IsCurrentState(State) && !bIsPostState))
	{
		NewEvent.Execute();
		return;
	}
	InitializationEvents.Add(NewEvent);
}