#ifdef IMGUI
/**
 * ╔══════════════════════════════════════════════════════════════════════╗
 * ║                         ACTOR PICKER WINDOW                          ║
 * ╠══════════════════════════════════════════════════════════════════════╣
 * ║                                                                      ║
 * ║  Interactive actor selection and debug inspection tool for ImGui     ║
 * ║                                                                      ║
 * ║  ┌─────────────────────────────────────────────────────────────┐     ║
 * ║  │ FEATURES:                                                   │     ║
 * ║  │ • Click-to-select actors in the world                       │     ║
 * ║  │ • Auto-detect ShowImGui() functions                         │     ║
 * ║  │ • Display actor info (name, class, location)                │     ║
 * ║  │ • Component debug info in tree nodes                        │     ║
 * ║  └─────────────────────────────────────────────────────────────┘     ║
 * ║                                                                      ║
 * ║  ┌─────────────────────────────────────────────────────────────┐     ║
 * ║  │ USAGE:                                                      │     ║
 * ║  │ 1. Open Actor Picker from ImGui Debug menu                  │     ║
 * ║  │ 2. Click "Start Picking" to enable selection                │     ║
 * ║  │ 3. Click on any actor in the world                          │     ║
 * ║  │ 4. View debug information and component data                │     ║
 * ║  └─────────────────────────────────────────────────────────────┘     ║
 * ║                                                                      ║
 * ║  ┌─────────────────────────────────────────────────────────────┐     ║
 * ║  │ MAKING ACTORS DEBUGGABLE:                                   │     ║
 * ║  │ Add to your actor or component class:                       │     ║
 * ║  │   UFUNCTION() void ShowImGui() { DEBUG CODE }               │     ║
 * ║  └─────────────────────────────────────────────────────────────┘     ║
 * ║                                                                      ║
 * ╚══════════════════════════════════════════════════════════════════════╝
 */
UCLASS()
class UJesterActorPickerWindow : UImGuiWindow
{
	UPROPERTY()
	AActor SelectedActor;

	UPROPERTY()
	bool bPickingMode = false;

	UPROPERTY()
	bool bShowHighlight = true;

	UPROPERTY()
	TArray<UActorComponent> CachedComponents;

	UPROPERTY()
	FString ActorFilterText = "";

	UFUNCTION(BlueprintOverride, meta = (BlueprintThreadSafe))
	void OnPostInitProperties()
	{
		Init("Actor Picker", "Debug", true);
	}

	UFUNCTION(BlueprintOverride)
	void Show()
	{
		APlayerController PC = Gameplay::GetPlayerController(0);
		if (PC == nullptr)
		{
			ImGui::Text("No player controller found");
			return;
		}

		// Draw highlight on selected actor if enabled
		if (bShowHighlight && SelectedActor != nullptr && System::IsValid(SelectedActor))
		{
			Jester::DrawPulsingDebugBoundsForActor(SelectedActor, FLinearColor(1.0f, 1.0f, 0.0f, 1.0f), 2.0f);
		}

		// Picking mode toggle
		if (ImGui::Button(bPickingMode ? "Stop Picking" : "Start Picking"))
		{
			bPickingMode = !bPickingMode;
		}

		ImGui::SameLine();

		// Quick select player character button
		if (ImGui::Button("Select Player Character"))
		{
			APawn PlayerPawn = PC.ControlledPawn;
			if (PlayerPawn != nullptr)
			{
				SelectActor(PlayerPawn);
				bPickingMode = false;
			}
		}

		ImGui::SameLine();

		// Toggle highlight checkbox
		ImGui::Checkbox("Show Highlight", bShowHighlight);

		ImGui::Separator();

		// Actor selection dropdown with filter
		ImGui::Text("Select Actor:");
		ImGui::PushItemWidth(300.0f);
		ImGui::InputText("##ActorFilter", ActorFilterText);
		ImGui::PopItemWidth();
		ImGui::SameLine();

		FString ComboLabel = SelectedActor != nullptr ? SelectedActor.GetName().ToString() : "Choose Actor...";

		// Use BeginCombo for proper dropdown
		if (ImGui::BeginCombo("##ActorCombo", ComboLabel))
		{
			ShowActorDropdown(PC);
			ImGui::EndCombo();
		}

		if (bPickingMode)
		{
			ImGui::SameLine();
			ImGui::TextColored(FColor::Yellow, "[Click on an actor to select]");

			// Check if we clicked outside ImGui windows
			if (ImGui::IsMouseClicked(EImGuiMouseButton::Left, false))
			{
				PerformActorPick(PC);
				bPickingMode = false;
			}
		}

		ImGui::Separator();

		// Show selected actor info
		if (SelectedActor != nullptr)
		{
			if (!System::IsValid(SelectedActor))
			{
				SelectedActor = nullptr;
				CachedComponents.Empty();
				return;
			}

			ImGui::Text(f"Selected Actor: {SelectedActor.GetName()}");
			ImGui::Text(f"Class: {SelectedActor.Class.GetName()}");
			ImGui::Text(f"Location: {SelectedActor.GetActorLocation().ToString()}");

			ImGui::Separator();

			// Check if actor has ShowImGui function
			if (Jester::HasFunctionWithName(SelectedActor, n"ShowImGui"))
			{
				if (ImGui::TreeNode("Actor Debug"))
				{
					ImGui::Separator();
					ImGui::Indent();
					Jester::CallFunctionByName(SelectedActor, n"ShowImGui");
					ImGui::Unindent();
					ImGui::Separator();
					ImGui::TreePop();
				}
			}

			// Show all components in a resizable child window
			ImGui::Separator();
			ImGui::Text(f"Components ({CachedComponents.Num()}):");

			// Create a resizable child window for components that auto-adjusts height
			if (ImGui::BeginChild("ComponentsList", FVector2f(0, 0), false, EImGuiWindowFlags::None))
			{
				for (UActorComponent Component : CachedComponents)
				{
					if (!System::IsValid(Component))
						continue;

					FString CompName = Component.GetName().ToString();
					FString CompClass = Component.Class.GetName().ToString();
					bool bHasShowImGui = Jester::HasFunctionWithName(Component, n"ShowImGui");

					// Show component with different styling based on whether it has ShowImGui
					if (bHasShowImGui)
					{
						// Has ShowImGui - show as tree node
						if (ImGui::TreeNode(f"[+] {CompName} ({CompClass})##comp_{Component.GetFullName()}"))
						{
							ImGui::BeginGroupPanel(f"", FVector2D(ImGui::GetWindowContentRegionWidth() - ImGui::GetCursorPosX(), 0));
							Jester::CallFunctionByName(Component, n"ShowImGui");
							ImGui::EndGroupPanel();
							ImGui::TreePop();
						}
					}
					else
					{
						// No ShowImGui - show as disabled text
						ImGui::BeginDisabled();
						ImGui::Text(f"    {CompName} ({CompClass})");
						ImGui::EndDisabled();
					}
				}
			}
			ImGui::EndChild();

			// Clear selection button
			ImGui::Separator();
			if (ImGui::Button("Clear Selection"))
			{
				SelectedActor = nullptr;
				CachedComponents.Empty();
			}
		}
		else
		{
			ImGui::Text("No actor selected");
		}
	}

	void PerformActorPick(APlayerController PC)
	{
		float32 MouseX = 0;
		float32 MouseY = 0;
		PC.GetMousePosition(MouseX, MouseY);

		FVector WorldLocation;
		FVector WorldDirection;
		if (PC.DeprojectScreenPositionToWorld(MouseX, MouseY, WorldLocation, WorldDirection))
		{
			FHitResult HitResult;
			FVector TraceStart = WorldLocation;
			FVector TraceEnd = WorldLocation + (WorldDirection * 10000.0);

			FCollisionQueryParams QueryParams;
			QueryParams.bTraceComplex = true;
			QueryParams.bReturnPhysicalMaterial = false;

			if (System::LineTraceSingleByChannel(HitResult, TraceStart, TraceEnd, ECollisionChannel::ECC_Visibility, QueryParams))
			{
				AActor HitActor = HitResult.Actor;
				if (HitActor != nullptr)
				{
					SelectActor(HitActor);
				}
			}
		}
	}

	void SelectActor(AActor Actor)
	{
		SelectedActor = Actor;
		CachedComponents.Empty();

		// Cache all components and sort them (debuggable first)
		TSet<UActorComponent> AllComponents;
		Actor.GetComponentsByClass(AllComponents);
		TArray<UActorComponent> DebuggableComponents;
		TArray<UActorComponent> NonDebuggableComponents;

		// Separate components into debuggable and non-debuggable
		for (UActorComponent Comp : AllComponents)
		{
			if (Jester::HasFunctionWithName(Comp, n"ShowImGui"))
			{
				DebuggableComponents.Add(Comp);
			}
			else
			{
				NonDebuggableComponents.Add(Comp);
			}
		}

		// Add debuggable components first, then non-debuggable
		for (UActorComponent Comp : DebuggableComponents)
		{
			CachedComponents.Add(Comp);
		}
		for (UActorComponent Comp : NonDebuggableComponents)
		{
			CachedComponents.Add(Comp);
		}

		Print(f"Selected Actor: {Actor.GetName()} with {CachedComponents.Num()} components ({DebuggableComponents.Num()} debuggable)");
	}

	void ShowActorDropdown(APlayerController PC)
	{
		// Only search for actors when dropdown is open (lazy loading)

		// Get all actors in the world
		TArray<AActor> AllActors;
		GetAllActorsOfClass(AActor, AllActors);

		// Show count of actors
		int32 FilteredCount = 0;

		// Filter and display actors
		for (AActor Actor : AllActors)
		{
			if (!System::IsValid(Actor))
				continue;

			FString ActorName = Actor.GetName().ToString();
			FString ActorClass = Actor.Class.GetName().ToString();

			// Apply filter
			if (!ActorFilterText.IsEmpty())
			{
				if (!ActorName.Contains(ActorFilterText, ESearchCase::IgnoreCase) &&
					!ActorClass.Contains(ActorFilterText, ESearchCase::IgnoreCase))
				{
					continue;
				}
			}

			FilteredCount++;
			FString DisplayName = f"{ActorName} ({ActorClass})";

			// Selectable item
			bool bIsSelected = (SelectedActor == Actor);
			if (ImGui::Selectable(DisplayName, bIsSelected))
			{
				SelectActor(Actor);
			}

			// Highlight on hover
			if (ImGui::IsItemHovered())
			{
				ImGui::SetTooltip(f"Location: {Actor.GetActorLocation().ToString()}");
			}
		}

		// Show message if no actors found
		if (FilteredCount == 0)
		{
			ImGui::TextDisabled("No actors found");
		}
	}
}
#endif