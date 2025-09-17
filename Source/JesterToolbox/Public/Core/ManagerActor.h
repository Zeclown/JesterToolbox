// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ManagerActor.generated.h"

UCLASS()
class JESTERTOOLBOX_API AManagerActor : public AActor
{
	GENERATED_BODY()

public:
	UFUNCTION()
	void BeginPlay() override;

	UFUNCTION()
	void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
};
