/**
 * Base class for all capabilities in the Jester Toolbox capability system.
 *
 * Capabilities represent discrete character abilities or actions that can be enabled/disabled
 * based on game conditions. They integrate with the input system and can be organized
 * into complex trees using capability nodes.
 *
 * Usage Example:
 * ```
	class UJumpCapability_AS : UCapability_AS
	{
		UFUNCTION(BlueprintOverride)
		void OnEnableCapability()
		{
			GetCharacter().Jump();
		}

		UFUNCTION(BlueprintOverride)
		void OnDisableCapability()
		{
			GetCharacter().StopJumping();
		}

		UFUNCTION(BlueprintOverride)
		bool ShouldEnable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character)
		{
			return GetActionManager().WasActionActivated(GameplayTags::Input_Jump, 0.2);
		}

		UFUNCTION(BlueprintOverride)
		bool ShouldDisable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character)
		{
			return GetTimeEnabled() > 0.2;
		}
	}
 * ```
 */
UCLASS(Abstract)
class UCapability_AS : UObject
{
	/**
	 * Tags that identify this capability type - used for prevention and categorization
	 * Can be checked against prevented capability tags to block activation
	 */
	FGameplayTagContainer CapabilityTags;

	/** Internal flag tracking whether this capability is currently active */
	bool bIsEnabled = false;
	private float EnableStartTime = -1;

	/**
	 * Gets the capability system component that owns this capability
	 * @return The parent capability system component
	 */
	UCapabilitySystemComponent_AS GetSystemComponent() const
	{
		return Cast<UCapabilitySystemComponent_AS>(GetOuter());
	}

	/**
	 * Gets the character that owns this capability
	 * @return The character associated with this capability's system component
	 */
	ACharacter GetCharacter() const
	{
		return GetSystemComponent().GetCharacter();
	}

	/**
	 * Gets the player controller associated with this capability
	 * @return The player controller for this capability's character
	 */
	APlayerController GetPlayerController() const
	{
		return GetSystemComponent().GetPlayerController();
	}

	/**
	 * Gets the action manager for this capability's character
	 * Used to manage and execute actions associated with this capability
	 *
	 * @return The action manager instance for the character
	 */
	UActionManager_AS GetActionManager() const
	{
		return UActionManager_AS::Get(GetCharacter());
	}

	/**
	 * Get time since this capability was enabled
	 * @return Time in seconds since the capability was enabled, or -1 if not enabled
	 */
	float GetTimeEnabled() const
	{
		if (EnableStartTime < 0)
		{
			return -1;
		}
		return System::GetGameTimeInSeconds() - EnableStartTime;
	}

	/**
	 * Internal method called when the capability becomes active
	 * This is called by the capability system - override OnEnableCapability instead
	 */
	void EnableCapability() final
	{
		bIsEnabled = true;
		EnableStartTime = System::GetGameTimeInSeconds();
		OnEnableCapability();
	}

	/**
	 * Internal method called when the capability becomes inactive
	 * This is called by the capability system - override OnDisableCapability instead
	 */
	void DisableCapability() final
	{
		bIsEnabled = false;
		EnableStartTime = -1;
		OnDisableCapability();
	}

	/**
	 * Internal method called every frame while the capability is active
	 * This is called by the capability system - override OnTickActive instead
	 */
	void TickActive(float DeltaTime) final
	{
		// Called every frame while the capability is active
		OnTickActive(DeltaTime);
	}

	/**
	 * Internal method that checks if the capability should be enabled
	 * Handles prevention tag checking before calling user-defined ShouldEnable
	 */
	bool CheckShouldEnable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character) final
	{
		if (CapabilitySystem.GetPreventedCapabilities().CurrentTags.HasAny(CapabilityTags))
		{
			return false;
		}

		return ShouldEnable(CapabilitySystem, Character);
	}

	/**
	 * Internal method that checks if the capability should be disabled
	 * Directly calls user-defined ShouldDisable method
	 */
	bool CheckShouldDisable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character) final
	{
		return ShouldDisable(CapabilitySystem, Character);
	}

	/**
	 * Called when the capability is activated
	 * Override this to implement capability-specific behavior on activation
	 *
	 * @param InputComponent The input component for binding input actions
	 */
	UFUNCTION(BlueprintEvent)
	void OnEnableCapability()
	{
	}

	/**
	 * Called when the capability is deactivated
	 * Override this to implement capability-specific cleanup behavior
	 */
	UFUNCTION(BlueprintEvent)
	void OnDisableCapability()
	{
	}

	/**
	 * Called every frame while the capability is active
	 * Override this to implement per-frame capability logic
	 *
	 * @param DeltaTime Time elapsed since last frame
	 */
	UFUNCTION(BlueprintEvent)
	void OnTickActive(float DeltaTime)
	{
	}

	/**
	 * Determines whether this capability should become active
	 * Override this to implement capability-specific activation conditions
	 *
	 * @param CapabilitySystem The capability system managing this capability
	 * @param Character The character this capability belongs to
	 * @return True if the capability should be enabled
	 */
	UFUNCTION(BlueprintEvent)
	bool ShouldEnable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character)
	{
		return true;
	}

	/**
	 * Determines whether this capability should become inactive
	 * Override this to implement capability-specific deactivation conditions
	 *
	 * @param CapabilitySystem The capability system managing this capability
	 * @param Character The character this capability belongs to
	 * @return True if the capability should be disabled
	 */
	UFUNCTION(BlueprintEvent)
	bool ShouldDisable(UCapabilitySystemComponent_AS CapabilitySystem, ACharacter Character)
	{
		return false;
	}

	/**
	 * Creates a capability node wrapper for this capability
	 * Used internally by the capability system to integrate with capability trees
	 *
	 * @return A leaf node containing this capability
	 */
	UCapabilityNode_AS GenerateCompoundNode()
	{
		ULeafNode_AS LeafNode = ULeafNode_AS();
		LeafNode.Init(GetClass(), this);
		return LeafNode;
	}

#ifdef IMGUI
	/**
	 * Debug method for displaying capability information in ImGui
	 * Override this to show capability-specific debug information
	 */
	void ShowImGui()
	{
	}
#endif
}