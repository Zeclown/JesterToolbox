struct FGameplayTagAggregator
{
    FGameplayTagContainer CurrentTags;

    TMap<FString, FGameplayTagContainer> TagByReason;

    void AddTag(FGameplayTag Tag, FString Reason)
    {
        TagByReason.FindOrAdd(Reason).AddTag(Tag);
        if (!CurrentTags.HasTag(Tag))
        {
            CurrentTags.AddTag(Tag);
        }
    }

    void RemoveTag(FGameplayTag Tag, FString Reason)
    {
        FGameplayTagContainer& TagContainer = TagByReason.FindOrAdd(Reason);
        TagContainer.RemoveTag(Tag);
        if(TagContainer.Num() == 0)
        {
            TagByReason.Remove(Reason);
        }

        if (CurrentTags.HasTag(Tag))
        {
            // Go through all the reasons and check if the tag is still present
            bool bStillPresent = false;
            for (const auto& Pair : TagByReason)
            {
                if (Pair.Value.HasTag(Tag))
                {
                    bStillPresent = true;
                    break;
                }
            }
            if (!bStillPresent)
            {
                CurrentTags.RemoveTag(Tag);
            }
        }
    }

#ifdef IMGUI
    void ShowImGui()
    {
        // Show the current tags, and for each tag, show the reasons it was added
        ImGui::Text("Current Tags:");
        for (const auto& Tag : CurrentTags.GameplayTags)
        {
            ImGui::Text(f"- {Tag.ToString()}");
            for (const auto& Pair : TagByReason)
            {
                if (Pair.Value.HasTag(Tag))
                {
                    ImGui::Text(f"  - {Pair.Key}");
                }
            }
        }
    }
#endif
}