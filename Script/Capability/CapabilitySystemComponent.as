/**
 * Component that manages a collection of capabilities for a character
 *
 * This system allows characters to have complex, conditional abilities that can be
 * organized into tree structures. Capabilities can be prevented from activating
 * using gameplay tags, and the system handles automatic enabling/disabling based
 * on game conditions.
 *
 * Usage Example:
 * ```
 * // In character blueprint or code:
 * CapabilitySystem.Capabilities.Add(UJumpCapability_AS::StaticClass());
 * CapabilitySystem.Capabilities.Add(USprintCapability_AS::StaticClass());
 *
 * // To prevent jumping:
 * CapabilitySystem.GetPreventedCapabilities().AddTag(JumpTag, "Stunned");
 * ```
 */
class UCapabilitySystemComponent_AS : UActorComponent
{
	/**
	 * Array of capability classes to initialize when the component starts
	 * These capabilities will be added to the root parallel node
	 */
	UPROPERTY()
	TArray<TSubclassOf<UCapability_AS>> Capabilities;

	/**
	 * Array of capability sheets containing grouped capabilities
	 * Useful for organizing capabilities by theme or character type
	 */
	UPROPERTY()
	TArray<UCapabilitySheet_AS> CapabilitySheets;

	/**
	 * Root node of the capability tree - runs all child capabilities in parallel
	 * This is the top-level container for all capability logic
	 */
	UPROPERTY(VisibleInstanceOnly)
	private UParallelSequence_AS RootCapabilityNode;

	/**
	 * List of currently active capabilities
	 * Updated each frame based on capability tree evaluation
	 */
	UPROPERTY(VisibleInstanceOnly, Transient)
	private TArray<UCapability_AS> ActiveCapabilities;

	/**
	 * Aggregator tracking which capability tags are currently prevented
	 * Capabilities with these tags will not be allowed to activate
	 */
	UPROPERTY(VisibleInstanceOnly)
	private FGameplayTagAggregator PreventedCapabilities;

	/**
	 * Gets the prevented capabilities aggregator for external modification
	 * @return Reference to the prevented capabilities aggregator
	 */
	UFUNCTION(BlueprintPure)
	FGameplayTagAggregator GetPreventedCapabilities() const
	{
		return PreventedCapabilities;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RootCapabilityNode = NewObject(this, UParallelSequence_AS);
		for (TSubclassOf<UCapability_AS> EachCapability : Capabilities)
		{
			UCapability_AS Capability = NewObject(this, EachCapability);
			if (Capability != nullptr)
			{
				RootCapabilityNode.Do(Capability.GenerateCompoundNode());
			}
		}

		for (UCapabilitySheet_AS EachSheet : CapabilitySheets)
		{
			for (TSubclassOf<UCapability_AS> EachCapability : EachSheet.Capabilities)
			{
				UCapability_AS Capability = NewObject(this, EachCapability);
				if (Capability != nullptr)
				{
					RootCapabilityNode.Do(Capability.GenerateCompoundNode());
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateCapabilityNodes(DeltaSeconds);
	}

	private void AddCapabilityBranch(UCapabilityNode_AS RootNode)
	{
		if (RootNode == nullptr)
		{
			return;
		}

		RootCapabilityNode.Do(RootNode);
	}

	/**
	 * Gets the character that owns this capability system
	 * @return The character actor that owns this component
	 */
	ACharacter GetCharacter()
	{
		return Cast<ACharacter>(GetOwner());
	}

	/**
	 * Gets the player controller associated with this capability system
	 * @return The player controller controlling the owning character
	 */
	APlayerController GetPlayerController()
	{
		return Cast<APlayerController>(GetCharacter().Controller);
	}

	/**
	 * Gets the input component for binding capability input actions
	 * @return The input component from the player controller, or null if not available
	 */
	UInputComponent GetInputComponent()
	{
		APlayerController PlayerController = GetPlayerController();
		if (PlayerController != nullptr)
		{
			return PlayerController.GetComponentByClass(UInputComponent);
		}
		return nullptr;
	}

	/**
	 * Updates the capability tree and manages active capabilities
	 * Called every frame to evaluate capability conditions and update active state
	 *
	 * @param DeltaSeconds Time elapsed since last update
	 */
	void UpdateCapabilityNodes(float DeltaSeconds)
	{
		FCapabilityNodeExecutionResult Result = RootCapabilityNode.UpdateActiveNodes(this);
		ActiveCapabilities = Result.EnabledCapabilities;
		for (UCapability_AS Capability : ActiveCapabilities)
		{
			if (Capability != nullptr)
			{
				Capability.TickActive(DeltaSeconds);
			}
		}
	}

	bool IsCapabilityEnabled(TSubclassOf<UCapability_AS> CapabilityClass)
	{
		for (UCapability_AS Capability : ActiveCapabilities)
		{
			if (Capability.IsA(CapabilityClass))
			{
				return true;
			}
		}
		return false;
	}
#ifdef IMGUI
	UFUNCTION()
	void ShowImGui()
	{
		ImGui::Text(f"Capabilities ({Capabilities.Num()}):");
		ImGui::Separator();
		ImGui::Text("Prevented Capabilities:");
		ImGui::Indent();
		PreventedCapabilities.ShowImGui();
		ImGui::Unindent();

		if (ImGui::TreeNode("Capability Tree"))
		{
			RootCapabilityNode.ShowImGui();
			ImGui::TreePop();
		}
	}
#endif
}