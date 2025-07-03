/**
 * Action Manager component for handling input actions with Enhanced Input system
 *
 * This component should be placed on a Pawn and provides a centralized way to manage
 * input actions using gameplay tags. It tracks action states, timing information,
 * and provides convenient query methods for checking action status.
 *
 * Features:
 * - Tag-based action registration and lookup
 * - Action state tracking (active, triggered, completed)
 * - Timing information for recent actions
 * - Debug logging and ImGui visualization
 *
 * Usage Example:
 * ```
 * // Register an action
 * FRegisteredInputAction JumpAction(GameplayTags::Input_Jump, JumpInputAction);
 * ActionManager.RegisterAction(JumpAction);
 *
 * // Check action state
 * if (ActionManager.IsActionActive(GameplayTags::Input_Jump))
 * {
 *     // Handle jump input
 * }
 *
 * // Check recent action
 * if (ActionManager.WasActionTriggered(GameplayTags::Input_Jump, 0.1f))
 * {
 *     // Jump was pressed within last 0.1 seconds
 * }
 * ```
 */
class UActionManager_AS : UActorComponent
{
	// Legacy array - consider removing in favor of the map-based approach
	TArray<FRegisteredInputAction> RegisteredInputActions;

	/** Enhanced input component that handles the actual input binding */
	UEnhancedInputComponent InputComponent;

	/** Map of gameplay tags to registered input actions for fast lookup */
	UPROPERTY()
	private TMap<FGameplayTag, FRegisteredInputAction> RegisteredActions;

	/** Reverse map for looking up tags from input actions during callbacks */
	private TMap<UInputAction, FGameplayTag> ActionToTagMap;

	/** Runtime data tracking action states and timing information */
	private TMap<FGameplayTag, FRegisteredInputActionRuntimeData> RegisteredActionsRuntimeData;

	bool bIsInitialized = false;

	/** Debug logging for input events */
	private FLogHistory LogHistory = FLogHistory(true, true, true, true, n"Input");

	/**
	 * Registers an input action with the action manager
	 *
	 * This creates the mapping between gameplay tags and input actions, and sets up
	 * the runtime data tracking for the action. Each action can only be registered once.
	 *
	 * @param RegisteredAction The action configuration to register
	 */
	void RegisterAction(FRegisteredInputAction RegisteredAction)
	{
		RegisteredActions.Add(RegisteredAction.ActionTag, RegisteredAction);
		RegisteredActionsRuntimeData.Add(RegisteredAction.ActionTag, FRegisteredInputActionRuntimeData());
		ActionToTagMap.Add(RegisteredAction.Action, RegisteredAction.ActionTag);

		if (bIsInitialized)
		{
			// If already initialized, register the action immediately
			RegisterActionInternal(RegisteredAction);
		}
	}

	/**
	 * Checks if an action is currently active (pressed/held down)
	 *
	 * @param ActionTag The gameplay tag identifying the action
	 * @return True if the action is currently being held down
	 */
	UFUNCTION(BlueprintPure)
	bool IsActionActive(FGameplayTag ActionTag) const
	{
		if (RegisteredActionsRuntimeData.Contains(ActionTag))
		{
			return RegisteredActionsRuntimeData[ActionTag].bIsActive;
		}
		return false;
	}

	/**
	 * Checks if an action was triggered within a specified time window
	 *
	 * Useful for implementing input buffering or checking for recent button presses.
	 *
	 * @param ActionTag The gameplay tag identifying the action
	 * @param MaxTimeAgo Maximum time in seconds to look back
	 * @return True if the action was triggered within the time window
	 */
	UFUNCTION(BlueprintPure)
	bool WasActionTriggered(FGameplayTag ActionTag, float MaxTimeAgo) const
	{
		if (RegisteredActionsRuntimeData.Contains(ActionTag))
		{
			if (RegisteredActionsRuntimeData[ActionTag].LastTimeTriggered <= 0.0)
			{
				return false;
			}

			return Gameplay::GetTimeSeconds() - RegisteredActionsRuntimeData[ActionTag].LastTimeTriggered <= MaxTimeAgo;
		}
		return false;
	}

	/**
	 * Checks if an action was activated (started) within a specified time window
	 *
	 * Different from triggered - this specifically tracks when the action first became active.
	 *
	 * @param ActionTag The gameplay tag identifying the action
	 * @param MaxTimeAgo Maximum time in seconds to look back
	 * @return True if the action was activated within the time window
	 */
	UFUNCTION(BlueprintPure)
	bool WasActionActivated(FGameplayTag ActionTag, float MaxTimeAgo) const
	{
		if (RegisteredActionsRuntimeData.Contains(ActionTag))
		{
			if (RegisteredActionsRuntimeData[ActionTag].LastActivationStartTime <= 0.0)
			{
				return false;
			}

			return Gameplay::GetTimeSeconds() - RegisteredActionsRuntimeData[ActionTag].LastActivationStartTime <= MaxTimeAgo;
		}
		return false;
	}

	/**
	 * Checks if an action was completed (released) within a specified time window
	 *
	 * Useful for detecting recent button releases or action completions.
	 *
	 * @param ActionTag The gameplay tag identifying the action
	 * @param MaxTimeAgo Maximum time in seconds to look back
	 * @return True if the action was completed within the time window
	 */
	UFUNCTION(BlueprintPure)
	bool WasActionCompleted(FGameplayTag ActionTag, float MaxTimeAgo) const
	{
		if (RegisteredActionsRuntimeData.Contains(ActionTag))
		{
			if (RegisteredActionsRuntimeData[ActionTag].LastTimeCompleted <= 0.0)
			{
				return false;
			}

			return Gameplay::GetTimeSeconds() - RegisteredActionsRuntimeData[ActionTag].LastTimeCompleted <= MaxTimeAgo;
		}
		return false;
	}

	/**
	 * Initializes the action manager and sets up input bindings
	 * Creates the enhanced input component and binds all registered actions
	 */
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		APawn PlayerPawn = Cast<APawn>(GetOwner());
		check(PlayerPawn != nullptr, "ActionManager_AS must be placed on a Pawn.");

		// Create the enhanced input component for handling input events
		InputComponent = UEnhancedInputComponent::Create(GetOwner(), n"ActionManagerInputComponent");

		// Bind all registered actions to their respective event handlers
		for (auto EachAction : RegisteredActions)
		{
			RegisterActionInternal(EachAction.Value);
		}

		bIsInitialized = true;
		LogHistory.AddLog(f"ActionManager initialized with {RegisteredActions.Num()} actions.", EJesterLogVerbosity::Verbose);
	}

	void RegisterActionInternal(const FRegisteredInputAction& EachAction)
	{
		// Create delegate bindings for different input events
		FEnhancedInputActionHandlerDynamicSignature StartActionBinding;
		StartActionBinding.BindUFunction(this, n"HandleActionStart");

		FEnhancedInputActionHandlerDynamicSignature EndActionBinding;
		EndActionBinding.BindUFunction(this, n"HandleActionCompleted");

		FEnhancedInputActionHandlerDynamicSignature TriggeredActionBinding;
		TriggeredActionBinding.BindUFunction(this, n"HandleActionTriggered");

		FEnhancedInputActionHandlerDynamicSignature CancelActionBinding;
		CancelActionBinding.BindUFunction(this, n"HandleActionCancelled");

		// Bind all event types for comprehensive action tracking
		InputComponent.BindAction(EachAction.Action, ETriggerEvent::Started, StartActionBinding);
		InputComponent.BindAction(EachAction.Action, ETriggerEvent::Completed, EndActionBinding);
		InputComponent.BindAction(EachAction.Action, ETriggerEvent::Canceled, CancelActionBinding);
		InputComponent.BindAction(EachAction.Action, ETriggerEvent::Triggered, TriggeredActionBinding);
	}

	/**
	 * Handles the start event when an action begins (key/button pressed)
	 * Updates runtime data to mark the action as active and record timing
	 */
	UFUNCTION()
	private void HandleActionStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		FGameplayTag ActionTag = ActionToTagMap[SourceAction];
		FRegisteredInputActionRuntimeData& RuntimeData = RegisteredActionsRuntimeData[ActionTag];

		LogHistory.AddLog(f"Action {SourceAction.GetName()} started with value {ActionValue.ToString()} at time {Gameplay::GetTimeSeconds()}.", EJesterLogVerbosity::Verbose);

		RuntimeData.LastActivationStartTime = Gameplay::GetTimeSeconds();
		RuntimeData.bIsActive = true;
	}

	/**
	 * Handles the completion event when an action ends (key/button released)
	 * Updates runtime data to mark the action as inactive and record completion time
	 */
	UFUNCTION()
	private void HandleActionCompleted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		FGameplayTag ActionTag = ActionToTagMap[SourceAction];
		FRegisteredInputActionRuntimeData& RuntimeData = RegisteredActionsRuntimeData[ActionTag];

		LogHistory.AddLog(f"Action {SourceAction.GetName()} completed with value {ActionValue.ToString()} at time {Gameplay::GetTimeSeconds()}.", EJesterLogVerbosity::Verbose);

		RuntimeData.LastTimeCompleted = Gameplay::GetTimeSeconds();
		RuntimeData.bIsActive = false;
	}

	/**
	 * Handles the triggered event during action execution
	 * Called continuously while the action is active (for continuous inputs)
	 */
	UFUNCTION()
	private void HandleActionTriggered(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		FGameplayTag ActionTag = ActionToTagMap[SourceAction];
		FRegisteredInputActionRuntimeData& RuntimeData = RegisteredActionsRuntimeData[ActionTag];

		LogHistory.AddLog(f"Action {SourceAction.GetName()} triggered with value {ActionValue.ToString()} at time {Gameplay::GetTimeSeconds()}.", EJesterLogVerbosity::Verbose);

		RuntimeData.LastTimeTriggered = Gameplay::GetTimeSeconds();
	}

	/**
	 * Handles the cancellation event when an action is interrupted
	 * Updates runtime data to mark the action as inactive
	 */
	UFUNCTION()
	private void HandleActionCancelled(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, const UInputAction SourceAction)
	{
		FGameplayTag ActionTag = ActionToTagMap[SourceAction];
		FRegisteredInputActionRuntimeData& RuntimeData = RegisteredActionsRuntimeData[ActionTag];

		LogHistory.AddLog(f"Action {SourceAction.GetName()} cancelled with value {ActionValue.ToString()} at time {Gameplay::GetTimeSeconds()}.", EJesterLogVerbosity::Verbose);

		RuntimeData.bIsActive = false;
	}

#ifdef IMGUI
	/**
	 * Debug visualization using ImGui
	 * Displays all registered actions and their current state information
	 */
	UFUNCTION()
	void ShowImGui()
	{
		ImGui::Text("Registered Actions:");
		ImGui::Indent();

		for (auto& EachAction : RegisteredActions)
		{
			ImGui::Text(f"Action: {EachAction.Value.Action.GetName()}");
			ImGui::Text(f"Tag: {EachAction.Value.ActionTag.ToString()}");

			FRegisteredInputActionRuntimeData& RuntimeData = RegisteredActionsRuntimeData[EachAction.Value.ActionTag];
			ImGui::Text(f"Last Triggered: {RuntimeData.LastTimeTriggered}");
			ImGui::Text(f"Last Completed: {RuntimeData.LastTimeCompleted}");
			ImGui::Text(f"Last Activation Start: {RuntimeData.LastActivationStartTime}");
			ImGui::BoolText("Is Active", RuntimeData.bIsActive);

			ImGui::Separator();
		}

		ImGui::Unindent();
		LogHistory.ShowImGui("ActionManager Log History");
	}
#endif
}

/**
 * Configuration structure for registering input actions
 *
 * Links a gameplay tag identifier with an actual input action asset.
 * This allows for tag-based action queries while maintaining the connection
 * to the Enhanced Input system.
 */
struct FRegisteredInputAction
{
	/** Default constructor */
	FRegisteredInputAction()
	{
		// Empty constructor for array initialization
	}

	/**
	 * Constructor with parameters
	 * @param InActionTag Gameplay tag to identify this action
	 * @param InAction Input action asset from Enhanced Input system
	 */
	FRegisteredInputAction(FGameplayTag InActionTag, UInputAction InAction)
	{
		ActionTag = InActionTag;
		Action = InAction;
	}

	/** Gameplay tag used to identify and query this action */
	FGameplayTag ActionTag;

	/** The actual input action asset from the Enhanced Input system */
	UInputAction Action;
}

/**
 * Runtime data structure tracking action state and timing information
 *
 * This data is updated by the action manager as input events occur.
 * Timing values use game time seconds and are set to -1 when not applicable.
 */
struct FRegisteredInputActionRuntimeData
{
	/** Last time the action was triggered (continuous event) */
	float LastTimeTriggered = -1;

	/** Last time the action was completed (released) */
	float LastTimeCompleted = -1;

	/** Last time the action was activated (started) */
	float LastActivationStartTime = -1;

	/** Whether the action is currently being held/pressed */
	bool bIsActive = false;
};