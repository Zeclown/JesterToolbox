event void FStateTrackerStateEvent(UStateTrackerComponent_AS InStateTracker, FGameplayTag InStateTag, bool bAdded);

struct FJesterState
{
	FJesterState()
	{
		// Default constructor
	}

	FJesterState(FGameplayTagContainer InBlockedActions)
	{
		BlockedActions = InBlockedActions;
	}

	// Actions that are blocked by this state
	UPROPERTY()
	FGameplayTagContainer BlockedActions;
}

class UStateTrackerComponent_AS : UActorComponent
{
	UPROPERTY()
	FStateTrackerStateEvent OnStateChanged;

	UPROPERTY(Meta = (Categories = "Character.State,Equipment.State", ForceInlineRow))
	TMap<FGameplayTag, FJesterState> StateMap;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly)
	FGameplayTagContainer CurrentStates;

	UFUNCTION(BlueprintCallable, Category = "ViceStateTracker")
	void AddState(FGameplayTag StateTag)
	{
		if (StateTag.IsValid() == false)
		{
			return;
		}

		if (StateMap.Contains(StateTag) == false)
		{
			check(false, "StateTag " + StateTag.ToString() + " not found in StateMap. Please add it to the map before using it.");
			return;
		}

		if (CurrentStates.HasTag(StateTag))
		{
			return;
		}

		CurrentStates.AddTag(StateTag);
		OnStateChanged.Broadcast(this, StateTag, true);
	}

	UFUNCTION(BlueprintCallable, Category = "ViceStateTracker")
	void RemoveState(FGameplayTag StateTag)
	{
		if (!CurrentStates.HasTag(StateTag))
		{
			return;
		}

		CurrentStates.RemoveTag(StateTag);
		OnStateChanged.Broadcast(this, StateTag, false);
	}

	UFUNCTION(BlueprintCallable, Category = "ViceStateTracker")
	bool PerformAction(FGameplayTag ActionTag, FGameplayTagContainer StatesToAdd, FGameplayTagContainer StatesToRemove)
	{
		if (!IsActionAllowed(ActionTag))
		{
			return false;
		}

		for (const FGameplayTag& State : StatesToAdd.GameplayTags)
		{
			AddState(State);
		}

		for (const FGameplayTag& State : StatesToRemove.GameplayTags)
		{
			RemoveState(State);
		}
		return true;
	}

	UFUNCTION(BlueprintPure, Category = "ViceStateTracker")
	bool IsActionAllowed(FGameplayTag ActionTag) const
	{
		// Check if the action is blocked by any current state
		for (const FGameplayTag& State : CurrentStates.GameplayTags)
		{
			if (StateMap.Contains(State) && StateMap[State].BlockedActions.HasTag(ActionTag))
			{
				return false;
			}
		}
		return true;
	}

	UFUNCTION(BlueprintPure, Category = "ViceStateTracker")
	bool IsInState(FGameplayTag StateTag) const
	{
		return CurrentStates.HasTag(StateTag);
	}
}