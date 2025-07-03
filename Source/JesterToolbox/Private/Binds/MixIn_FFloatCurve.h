#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "Utils/ScalableRuntimeCurve.h"
#include "MixIn_FFloatCurve.generated.h"

/**
 * 
 */
UCLASS(Meta = (ScriptMixin = "FRichCurve"))
class JESTERTOOLBOX_API UMixIn_FFloatCurve : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(ScriptCallable)
	static void AddKey(FRichCurve& Curve, float Time, float Value)
	{
		Curve.AddKey(Time, Value);
	}

	UFUNCTION(ScriptCallable) 
	static void RemoveKey(FRichCurve& Curve, float Time)
	{
		FKeyHandle KeyHandle = Curve.FindKey(Time);
		if (KeyHandle == FKeyHandle::Invalid())
			Curve.DeleteKey(KeyHandle);
		Curve.DeleteKey(KeyHandle);
	}

	UFUNCTION(ScriptCallable)
	static int GetNumKeys(FRichCurve const& Curve)
	{
		return Curve.GetNumKeys();
	}

	UFUNCTION(ScriptCallable)
	static float Evaluate(FRichCurve const& Curve, float InTime)
	{
		return Curve.Eval(InTime);
	}
};

UCLASS(Meta = (ScriptMixin = "FRuntimeFloatCurve"))
class JESTERTOOLBOX_API UMixIn_FRuntimeFloatCurve : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(ScriptCallable)
	static void AddKey(FRuntimeFloatCurve& Curve, float Time, float Value)
	{
		Curve.GetRichCurve()->AddKey(Time, Value);
	}

	UFUNCTION(ScriptCallable) 
	static void RemoveKey(FRuntimeFloatCurve& Curve, float Time)
	{
		FKeyHandle KeyHandle = Curve.GetRichCurve()->FindKey(Time);
		if (KeyHandle != FKeyHandle::Invalid())
		{
			Curve.GetRichCurve()->DeleteKey(KeyHandle);
		}
	}

	UFUNCTION(ScriptCallable)
	static int GetNumKeys(FRuntimeFloatCurve const& Curve)
	{
		return Curve.GetRichCurveConst()->GetNumKeys();
	}

	UFUNCTION(ScriptCallable)
	static float Evaluate(FRuntimeFloatCurve const& Curve, float InTime)
	{
		return Curve.GetRichCurveConst()->Eval(InTime);
	}
};

UCLASS(Meta = (ScriptMixin = "FScalableRuntimeCurve"))
class JESTERTOOLBOX_API UMixIn_FScalableRuntimeCurve : public UObject
{
	GENERATED_BODY()

public:

	
	UFUNCTION(ScriptCallable) 
	static bool HasCurve(FScalableRuntimeCurve const& ScalableCurve)
	{
		return ScalableCurve.HasCurve();
	}
	
	UFUNCTION(ScriptCallable) 
	static float Evaluate(FScalableRuntimeCurve const& ScalableCurve, float InTime)
	{
		return ScalableCurve.Evaluate(InTime);
	}
	
	UFUNCTION(ScriptCallable) 
	static void AddDefaultNormalizedKey(FScalableRuntimeCurve& ScalableCurve, float Time, float Value)
	{
		ScalableCurve.AddDefaultNormalizedKey(Time, Value);
	}
	
	UFUNCTION(ScriptCallable) 
	static void AddKeyOrSetNormalized(FScalableRuntimeCurve& ScalableCurve, float Time, float Value)
	{
		ScalableCurve.AddKeyOrSetNormalized(Time, Value);
	}
	
	UFUNCTION(ScriptCallable) 
	static void GetTimeRange(FScalableRuntimeCurve const& ScalableCurve, float& OutTime, float& OutValue)
	{
		ScalableCurve.GetTimeRange(OutTime, OutValue);
	}
};