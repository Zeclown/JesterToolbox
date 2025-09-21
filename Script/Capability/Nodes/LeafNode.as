/**
 * Leaf node that contains a single capability
 * 
 * This is the terminal node type that actually contains capability logic.
 * It evaluates whether its capability should be enabled/disabled and manages
 * the capability's lifecycle.
 */
class ULeafNode_AS : UCapabilityNode_AS
{
    /** The capability class this node manages */
    TSubclassOf<UCapability_AS> CapabilityClass;
    
    /** The capability instance this node manages */
    UCapability_AS Capability;

    /**
     * Initializes the leaf node with a capability class and instance
     * @param InCapabilityClass The class of capability to manage
     * @param InCapability The capability instance to manage
     */
    void Init(TSubclassOf<UCapability_AS> InCapabilityClass, UCapability_AS InCapability)
    {
        CapabilityClass = InCapabilityClass;
        Capability = InCapability;
    }

    /**
     * Returns whether the contained capability is currently enabled
     * @return True if the capability is active
     */
    bool IsEnabled() const override
    {
        return Capability.bIsEnabled;
    }

    /**
     * Updates the capability state and returns execution result
     * Handles enabling/disabling the capability based on its conditions
     * 
     * @param Component The capability system component
     * @return Result indicating if this capability should be active
     */
    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component) override
    {
        check(CapabilityClass != nullptr, "CapabilityClass is null");
        check(Capability != nullptr, "Capability is null. This should not happen.");
        FCapabilityNodeExecutionResult Result;
        Result.EnabledCapabilities.Empty();
        if(Capability.bIsEnabled)
        {
            if(Capability.CheckShouldDisable(Component, Component.GetCharacter()))
            {
                Capability.DisableCapability();
                return Result;
            }
            else
            {
                Result.EnabledCapabilities.Add(Capability);
                return Result;
            }
        }
        else if(Capability.bIsEnabled == false)
        {
            if(Capability.CheckShouldEnable(Component, Component.GetCharacter()))
            {
                Capability.EnableCapability();
                Result.EnabledCapabilities.Add(Capability);
                return Result;
            }
        }
        return Result;
    }
    
#ifdef IMGUI
    void ShowImGui() override
    {
        Super::ShowImGui();

        FColor Color = JesterColors::Dracula::Red;
        if(IsEnabled())
        {
            Color = JesterColors::Dracula::Green;
        }
        ImGui::PushStyleColor(EImGuiCol::Text, Color);
        if(ImGui::TreeNode(CapabilityClass.Get().GetName().ToString()))
        {
            ImGui::PopStyleColor();
            Capability.ShowImGui();
            ImGui::TreePop();
        }
        else
        {
            ImGui::PopStyleColor();
        }
    }
#endif
}