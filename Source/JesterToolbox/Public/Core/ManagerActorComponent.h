// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "ManagerActorComponent.generated.h"


UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class JESTERTOOLBOX_API UManagerActorComponent : public UActorComponent
{
	GENERATED_BODY()

	UFUNCTION()
	void BeginPlay() override;

	UFUNCTION()
	void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
};
