namespace FVector
{
	float Distance(const FVector& V1, const FVector& V2)
	{
		return (V2 - V1).Size();
	}

	float DistanceSquared(const FVector& V1, const FVector& V2)
	{
		return (V2 - V1).SizeSquared();
	}

	float Distance2D(const FVector& V1, const FVector& V2)
	{
		return (V2 - V1).Size2D();
	}

}

namespace FFloatRange
{
	FFloatRange MakeRange(float Min, float Max)
	{
		FFloatRange Range;
		Range.LowerBound.Value = Min;
		Range.UpperBound.Value = Max;
		return Range;
	}
}

mixin FVector2D To2D(FVector V)
{
	return FVector2D(V.X, V.Y);
}

mixin FVector To3D(FVector2D V)
{
	return FVector(V.X, V.Y, 0);
}

mixin FRotator ToYawRotator(FRotator R)
{
	return FRotator(0, R.Yaw, 0);
}

namespace Math
{
	UFUNCTION(BlueprintCallable, BlueprintPure)
	float GetAngleBetweenVectorsDegrees(FVector A, FVector B)
	{
		return Math::RadiansToDegrees(Math::Acos(A.GetSafeNormal().DotProduct(B.GetSafeNormal())));
	}

	// Function to get an angle in -180 to 180 range based on a lead vector as up and as second vector
	UFUNCTION(BlueprintCallable, BlueprintPure)
	float GetSignedAngleBetweenVectorsDegrees(FVector LeadVector, FVector SecondVector)
	{
		FVector A = LeadVector.GetSafeNormal();
		FVector B = SecondVector.GetSafeNormal();

		float Dot = Math::Clamp(A.DotProduct(B), -1.0f, 1.0f);
		float Angle = Math::RadiansToDegrees(Math::Acos(Dot));

		FVector Cross = A.CrossProduct(B);
		if (Cross.Z < KINDA_SMALL_NUMBER)
		{
			Angle = -Angle;
		}
		return Angle;
	}
	// Function to quickly get the flat topview normalized direction between 2 position.
	UFUNCTION(BlueprintCallable, BlueprintPure)
	FVector GetDirection2D(FVector Origin, FVector Destination)
	{
		FVector flatDirection = Destination - Origin;

		flatDirection = FVector(Origin.X, Origin.Y, 0.0);
		flatDirection.Normalize(0.00001);

		return flatDirection;
	}

	UFUNCTION(BlueprintCallable, BlueprintPure)
	float ApproximateHitImpact(FHitResult Hit, FVector Velocity)
	{
		// Compare velocity of the hit actor to the impact normal
		FVector HitVelocity = Velocity;
		FVector ImpactNormal = Hit.ImpactNormal;
		// Project the velocity onto the impact normal to get the component of velocity that is in the direction of the impact normal
		float ImpactVelocity = HitVelocity.ProjectOnToNormal(ImpactNormal).Size();
		return ImpactVelocity;
	}

	FRotator GetYawLookAt(FVector From, FVector To)
	{
		return FRotator::MakeFromXZ(To - From, FVector::UpVector);
	}

	float Clamp01(float Value)
	{
		return Math::Clamp(Value, 0.0f, 1.0f);
	}

	FVector ClampMagnitude01(FVector Value)
	{
		float Magnitude = Value.Size();
		if (Magnitude > 1.0f)
		{
			return Value / Magnitude;
		}
		return Value;
	}

	float DirectionToAngleXY(FVector Direction)
	{
		// Get the angle in degrees between the direction vector and the X axis
		float Angle = Math::Atan2(Direction.Y, Direction.X);
		return Math::RadiansToDegrees(Angle);
	}
}