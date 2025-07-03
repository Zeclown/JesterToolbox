mixin FString ToString(const FGameplayTagContainer& Container)
{
	FString Result = "{";
	for (int i = 0; i < Container.Num(); i++)
	{
		Result += Container.GameplayTags[i].ToString();
		if (i < Container.Num() - 1)
		{
			Result += ", ";
		}
	}
	Result += "}";
	return Result;
}

mixin void CompareToShadowTagContainer(const FGameplayTagContainer& Container, const FGameplayTagContainer& ShadowContainer, TArray<FGameplayTag>& out AddedTags, TArray<FGameplayTag>& out RemovedTags)
{
	for (FGameplayTag Tag : Container.GameplayTags)
	{
		if (!ShadowContainer.HasTag(Tag))
		{
			AddedTags.Add(Tag);
		}
	}

	for (FGameplayTag Tag : ShadowContainer.GameplayTags)
	{
		if (!Container.HasTag(Tag))
		{
			RemovedTags.Add(Tag);
		}
	}
}