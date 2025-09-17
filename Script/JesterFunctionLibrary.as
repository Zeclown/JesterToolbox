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
}