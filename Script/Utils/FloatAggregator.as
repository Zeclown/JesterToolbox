/**
 * Helper struct for replicating float aggregator entries
 * Required because Unreal cannot replicate TMap directly
 */
struct FFloatAggregatorReplicatedEntry
{
	/** Human-readable reason for this float value */
	UPROPERTY(SaveGame)
	FString Reason;

	/** The float value associated with this reason */
	UPROPERTY(SaveGame)
	float Value;
};

/**
 * Aggregates multiple float values with reasons for complex calculations
 * 
 * Supports both additive values and multiplicative modifiers. The final result
 * is calculated as: (DefaultValue + Sum(Values)) * Product(Multipliers)
 * 
 * Usage Example:
 * ```
 * FFloatAggregator Speed;
 * Speed.DefaultValue = 100.0f;           // Base speed
 * Speed.Add("SprintBonus", 50.0f);       // +50 speed when sprinting
 * Speed.Add("Encumbered", -20.0f);       // -20 speed when carrying items
 * Speed.Multiply("Haste", 1.5f);         // 1.5x multiplier from haste spell
 * Speed.Multiply("Slow", 0.7f);          // 0.7x multiplier from slow effect
 * 
 * float finalSpeed = Speed.GetTotal();   // (100 + 50 - 20) * 1.5 * 0.7 = 136.5
 * ```
 */
struct FFloatAggregator
{
	/** Array of additive float values with reasons */
	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, SaveGame)
	private TArray<FFloatAggregatorReplicatedEntry> Values;

	/** Array of multiplicative float values with reasons */
	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, SaveGame)
	private TArray<FFloatAggregatorReplicatedEntry> Multipliers;

	/** Base value used in calculations before additions and multiplications */
	UPROPERTY(SaveGame)
	float DefaultValue = 0.0f;

	/**
	 * Gets a copy of all multiplier entries
	 * @return Array of multiplier entries
	 */
	TArray<FFloatAggregatorReplicatedEntry> GetMultipliers() const
	{
		return Multipliers;
	}

	/**
	 * Gets a copy of all additive value entries
	 * @return Array of value entries
	 */
	TArray<FFloatAggregatorReplicatedEntry> GetValues() const
	{
		return Values;
	}

	/**
	 * Adds or updates an additive value with a reason
	 * @param Reason Human-readable identifier for this modifier
	 * @param Value The value to add to the total
	 */
	void Add(FString Reason, float Value)
	{
		FFloatAggregatorReplicatedEntry& Entry = FindOrAddValue(Reason);
		Entry.Value = Value;
	}

	/**
	 * Adds or updates a multiplicative modifier with a reason
	 * @param Reason Human-readable identifier for this multiplier
	 * @param Value The multiplier to apply (1.0 = no change, 2.0 = double, 0.5 = half)
	 */
	void Multiply(FString Reason, float Value)
	{
		FFloatAggregatorReplicatedEntry& Entry = FindOrAddMultiplier(Reason);
		Entry.Value = Value;
	}

	/**
	 * Gets the additive value associated with a reason
	 * @param Reason The reason to look up
	 * @return The additive value, or DefaultValue if not found
	 */
	float Get(FString Reason) const
	{
		for (auto& Entry : Values)
		{
			if (Entry.Reason == Reason)
			{
				return Entry.Value;
			}
		}
		return DefaultValue;
	}

	/**
	 * Removes a value or multiplier entry by reason
	 * @param Reason The reason of the entry to remove
	 */
	void Remove(FString Reason)
	{
		for (int i = 0; i < Values.Num(); i++)
		{
			if (Values[i].Reason == Reason)
			{
				Values.RemoveAt(i);
				return;
			}
		}
		for (int i = 0; i < Multipliers.Num(); i++)
		{
			if (Multipliers[i].Reason == Reason)
			{
				Multipliers.RemoveAt(i);
				return;
			}
		}
	}

	/**
	 * Calculates the total value after applying all additions and multiplications
	 * @return The final calculated total
	 */
	float GetTotal() const
	{
		float Total = DefaultValue;
		for (auto& Pair : Values)
		{
			Total += Pair.Value;
		}
		for (auto& Pair : Multipliers)
		{
			Total *= Pair.Value;
		}
		return Total;
	}

	/**
	 * Gets the multiplier value associated with a reason
	 * @param Reason The reason to look up
	 * @return The multiplier value, or 1.0 if not found
	 */
	float GetMultiplier(FString Reason)
	{
		for (auto& Entry : Multipliers)
		{
			if (Entry.Reason == Reason)
			{
				return Entry.Value;
			}
		}
		return 1.0f;
	}

	private FFloatAggregatorReplicatedEntry& FindOrAddValue(FString Reason)
	{
		for (auto& Entry : Values)
		{
			if (Entry.Reason == Reason)
			{
				return Entry;
			}
		}
		FFloatAggregatorReplicatedEntry NewEntry;
		NewEntry.Reason = Reason;
		Values.Add(NewEntry);
		return Values.Last();
	}

	private FFloatAggregatorReplicatedEntry& FindOrAddMultiplier(FString Reason)
	{
		for (auto& Entry : Multipliers)
		{
			if (Entry.Reason == Reason)
			{
				return Entry;
			}
		}
		FFloatAggregatorReplicatedEntry NewEntry;
		NewEntry.Reason = Reason;
		Multipliers.Add(NewEntry);
		return Multipliers.Last();
	}

}

namespace FFloatAggregator
{
	UFUNCTION(BlueprintCallable)
	void Add(FFloatAggregator & Aggregator, FString Reason, float Value)
	{
		Aggregator.Add(Reason, Value);
	}

	UFUNCTION(BlueprintCallable)
	void Multiply(FFloatAggregator & Aggregator, FString Reason, float Value)
	{
		Aggregator.Multiply(Reason, Value);
	}

	UFUNCTION(BlueprintCallable)
	float Get(FFloatAggregator & Aggregator, FString Reason)
	{
		return Aggregator.Get(Reason);
	}

	UFUNCTION(BlueprintCallable)
	void Remove(FFloatAggregator & Aggregator, FString Reason)
	{
		Aggregator.Remove(Reason);
	}

	UFUNCTION(BlueprintPure)
	float GetTotal(FFloatAggregator & Aggregator)
	{
		return Aggregator.GetTotal();
	}
}