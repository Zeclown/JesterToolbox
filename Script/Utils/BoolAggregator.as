/**
 * Helper struct for replicating boolean aggregator entries
 * Required because Unreal cannot replicate TMap directly
 */
struct FBoolAggregatorReplicatedEntry
{
	/** Human-readable reason for this boolean value */
	UPROPERTY()
	FString Reason;

	/** The boolean value associated with this reason */
	UPROPERTY()
	bool Value;
};

/**
 * Event delegate fired when the bool aggregator changes
 */
event void FBoolAggregatorChangedDelegate(FBoolAggregator Aggregator);

/**
 * Aggregates multiple boolean values with reasons for debugging and analysis
 * 
 * Useful for systems where multiple conditions can affect a boolean state.
 * Each entry has a reason string for debugging purposes.
 * 
 * Usage Example:
 * ```
 * FBoolAggregator CanMove;
 * CanMove.Add("NotStunned", true);
 * CanMove.Add("NotFrozen", false);
 * CanMove.Add("HasStamina", true);
 * 
 * bool canActuallyMove = CanMove.And(); // false (frozen)
 * bool anyMovementPossible = CanMove.Or(); // true (not stunned, has stamina)
 * ```
 */
struct FBoolAggregator
{
	/** Array of boolean values with associated reasons */
	TArray<FBoolAggregatorReplicatedEntry> Values;

	/** 
	 * Event fired when aggregator changes (local changes only, not replicated changes)
	 * Use with caution in multiplayer scenarios
	 */
	FBoolAggregatorChangedDelegate OnChanged;

	/**
	 * Adds or updates a boolean value with a reason
	 * @param Reason Human-readable identifier for this condition
	 * @param Value The boolean value to set
	 */
	void Add(FString Reason, bool Value)
	{
		FBoolAggregatorReplicatedEntry& ReplicatedValue = FindOrAddValue(Reason);
		ReplicatedValue.Value = Value;
		OnChanged.Broadcast(this);
	}

	/**
	 * Gets the boolean value for a specific reason
	 * @param Reason The reason to look up
	 * @return The boolean value, or false if reason not found
	 */
	bool Get(FString Reason)
	{
		for (auto& Entry : Values)
		{
			if (Entry.Reason == Reason)
			{
				return Entry.Value;
			}
		}
		return false;
	}

	/**
	 * Removes a boolean value entry by reason
	 * @param Reason The reason to remove
	 */
	void Remove(FString Reason)
	{
		for (int i = 0; i < Values.Num(); i++)
		{
			if (Values[i].Reason == Reason)
			{
				Values.RemoveAt(i);
				OnChanged.Broadcast(this);
				return;
			}
		}
	}

	/**
	 * Computes the logical AND of all boolean values
	 * @return true if all values are true, false otherwise (or true if no values)
	 */
	bool And() const
	{
		bool bResult = true;
		for (auto& Pair : Values)
		{
			bResult = bResult && Pair.Value;
		}
		return bResult;
	}

	/**
	 * Computes the logical OR of all boolean values  
	 * @return true if any value is true, false if all are false (or false if no values)
	 */
	bool Or() const
	{
		bool bResult = false;
		for (auto& Pair : Values)
		{
			bResult = bResult || Pair.Value;
		}
		return bResult;
	}

	private FBoolAggregatorReplicatedEntry& FindOrAddValue(FString Reason)
	{
		for (auto& Entry : Values)
		{
			if (Entry.Reason == Reason)
			{
				return Entry;
			}
		}
		FBoolAggregatorReplicatedEntry NewEntry;
		NewEntry.Reason = Reason;
		Values.Add(NewEntry);
		return Values.Last();
	}

#ifdef IMGUI
	void ShowImGui(FString Label, bool bShowLabel = true) const
	{
		if (bShowLabel)
		{
			ImGui::Text(Label);
		}
		ImGui::Indent();
		for (auto& Entry : Values)
		{
			ImGui::BoolText(Entry.Reason, Entry.Value);
		}
		ImGui::Unindent();
	}
#endif
};

namespace BoolAggregator
{
	UFUNCTION(BlueprintCallable, BlueprintPure)
	bool AggregatorAnd(FBoolAggregator Aggregator)
	{
		return Aggregator.And();
	}

	UFUNCTION(BlueprintCallable, BlueprintPure)
	bool AggregatorOr(FBoolAggregator Aggregator)
	{
		return Aggregator.Or();
	}

	UFUNCTION(BlueprintCallable)
	void Add(FBoolAggregator& Aggregator, FString Reason, bool Value)
	{
		Aggregator.Add(Reason, Value);
	}

	UFUNCTION(BlueprintCallable)
	void Remove(FBoolAggregator& Aggregator, FString Reason)
	{
		Aggregator.Remove(Reason);
	}

	UFUNCTION(BlueprintCallable, BlueprintPure)
	FString GetFirstReason(FBoolAggregator Aggregator, bool MatchingValue = false)
	{
		if (Aggregator.Values.IsEmpty() == false)
		{
			auto it = Aggregator.Values.Iterator();
			while (it.CanProceed)
			{
				auto Element = it.Proceed();
				if (Element.Value == MatchingValue)
				{
					return Element.Reason;
				}
			}
		}

		return "";
	}

}