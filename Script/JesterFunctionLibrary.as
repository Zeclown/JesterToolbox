namespace Jester
{
	UFUNCTION(BlueprintCallable, BlueprintPure)
	FTransform GetRelativeTransformToRoot(USceneComponent Component)
	{
		if (Component == nullptr)
		{
			return FTransform::Identity;
		}

		// Get the root component of the actor
		USceneComponent RootComponent = Component.GetOwner().GetRootComponent();
		if (RootComponent == nullptr)
		{
			return FTransform::Identity;
		}

		FTransform ComponentTransform = Component.GetWorldTransform();
		FTransform RootTransform = RootComponent.GetWorldTransform();
		// Calculate the relative transform
		FTransform RelativeTransform = ComponentTransform.GetRelativeTransform(RootTransform);
		return RelativeTransform;
	}

	/**
	 * Draws a debug box around an actor using its bounds
	 * Useful for highlighting selected actors in debug tools
	 *
	 * @param Actor The actor to highlight
	 * @param Color The color of the debug box (default: yellow)
	 * @param Duration How long to display the box in seconds (default: 0 for single frame)
	 * @param Thickness Line thickness (default: 2.0)
	 */
	UFUNCTION(BlueprintCallable, Category = "Jester|Debug")
	void DrawDebugBoundsForActor(AActor Actor, FLinearColor Color = FLinearColor(1.0f, 1.0f, 0.0f, 1.0f), float Duration = 0.0f, float Thickness = 2.0, float CorenerSize = 10.0)
	{
		if (Actor == nullptr)
			return;

		// Get actor bounds
		FVector Origin;
		FVector BoxExtent;
		Actor.GetActorBounds(false, Origin, BoxExtent);

		// Don't draw if the actor has no bounds
		if (BoxExtent.IsNearlyZero())
			return;

		// Get the actor's rotation for oriented box
		FRotator ActorRotation = Actor.GetActorRotation();

		// Draw the debug box
		System::DrawDebugBox(Origin, BoxExtent, Color, ActorRotation, Duration, Thickness);

		if (CorenerSize > 0.0)
		{
			// Draw small lines at each corner for emphasis
			for (int32 i = -1; i <= 1; i += 2)
			{
				for (int32 j = -1; j <= 1; j += 2)
				{
					for (int32 k = -1; k <= 1; k += 2)
					{
						FVector CornerOffset = FVector(BoxExtent.X * i, BoxExtent.Y * j, BoxExtent.Z * k);
						FVector CornerWorld = Origin + ActorRotation.RotateVector(CornerOffset);

						// Draw small cross at corner
						System::DrawDebugPoint(CornerWorld, CorenerSize, Color, Duration);
					}
				}
			}
		}
	}

	/**
	 * Continuously highlights an actor with a pulsing effect
	 * Call this every frame for a smooth pulsing highlight
	 *
	 * @param Actor The actor to highlight
	 * @param BaseColor The base color for the highlight
	 * @param PulseSpeed Speed of the pulse effect (default: 2.0)
	 */
	UFUNCTION(BlueprintCallable, Category = "Jester|Debug")
	void DrawPulsingDebugBoundsForActor(AActor Actor, FLinearColor BaseColor = FLinearColor(1.0f, 1.0f, 0.0f, 1.0f), float PulseSpeed = 2.0f)
	{
		if (Actor == nullptr)
			return;

		// Create pulsing effect
		float Time = System::GetGameTimeInSeconds();
		float PulseAlpha = (Math::Sin(Time * PulseSpeed) + 1.0f) * 0.5f;
		float Thickness = 1.0f + PulseAlpha * 3.0f;

		FLinearColor PulsingColor = BaseColor;
		PulsingColor.A = 0.5f + PulseAlpha * 0.5f;

		DrawDebugBoundsForActor(Actor, PulsingColor, 0.0f, Thickness);
	}
}