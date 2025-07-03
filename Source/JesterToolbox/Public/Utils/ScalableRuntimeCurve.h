#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "ScalableRuntimeCurve.generated.h"

/**
 * Curve that can be scaled in X and Y. Useful to keep a normalized curve and scale it to the desired range.
 */
USTRUCT(BlueprintType)
struct JESTERTOOLBOX_API FScalableRuntimeCurve
{
	GENERATED_BODY()


protected:
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float ScaleX = 1.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float ScaleY = 1.0f;

	bool HasCurve() const
	{
		return Curve.GetRichCurveConst()->Keys.Num() > 0;
	}
	
	float Evaluate(float InTime) const
	{
		return Curve.GetRichCurveConst()->Eval(InTime / ScaleX) * ScaleY;
	}

	void AddDefaultNormalizedKey(float Time, float Value)
	{
		Curve.EditorCurveData.UpdateOrAddKey(Time, Value);
	}

	void AddKeyOrSetNormalized(float Time, float Value)
	{
		Curve.GetRichCurve()->UpdateOrAddKey(Time, Value);
	}

	void GetTimeRange(float& OutTime, float& OutValue) const
	{
		float TimeStart, TimeEnd;
		Curve.GetRichCurveConst()->GetTimeRange(TimeStart, TimeEnd);
		OutTime = TimeEnd * ScaleX;
		OutValue = Curve.GetRichCurveConst()->Eval(TimeEnd) * ScaleY;
	}
	
};
