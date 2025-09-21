/**
 * Stateful First Valid node that remembers which child was last enabled
 * 
 * Similar to FirstValidNode but maintains state. Once a child is enabled,
 * it continues to run that child until it becomes disabled. Only then does
 * it search for a new valid child from the beginning.
 * 
 * Usage Example:
 * ```
 * // Create a weapon mode that sticks to current choice
 * UCompoundStatefulFirstValidNode_AS WeaponMode = UCompoundStatefulFirstValidNode_AS();
 * WeaponMode.State(SwordCapability)      // Sword combat
 *           .State(BowCapability)        // Ranged combat
 *           .State(MagicCapability);     // Magic combat  
 * // Once a mode is chosen, it stays active until conditions change
 * ```
 */
class UCompoundStatefulFirstValidNode_AS : UCapabilityNode_AS
{
    /** Array of child nodes to evaluate as states */
    TArray<UCapabilityNode_AS> ChildNodes;
    
    /** True if any child node is currently enabled */
    bool bHasEnabledChild = false;
    
    /** Index of the currently active child node */
    int CurrentNodeIndex = 0;

    /**
     * Returns true if any child node is currently enabled
     * @return True if a child state is active
     */
    bool IsEnabled() const override
    {
        return bHasEnabledChild;
    }

    /**
     * Adds a child node as a state option
     * @param Node The node to add as a state
     * @return This node for method chaining
     */
    UCompoundStatefulFirstValidNode_AS State(UCapabilityNode_AS Node)
    {
        Node.ParentNode = this;
        ChildNodes.Add(Node);
        return this;
    }

    /**
     * Convenience method to add a capability class as a state
     * @param CapabilityClass The capability class to add as a state
     * @return This node for method chaining
     */
    UCompoundStatefulFirstValidNode_AS State(TSubclassOf<UCapability_AS> CapabilityClass)
    {
        UCapability_AS Capability = NewObject(this, CapabilityClass);
        return State(Capability.GenerateCompoundNode());
    }

    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component) override
    {
        FCapabilityNodeExecutionResult Result;
        Result.EnabledCapabilities.Empty();
        if(ChildNodes.Num() == 0)
        {
            bHasEnabledChild = false;
            return Result;
        }   

        int PreviousNodeIndex = CurrentNodeIndex;
        FCapabilityNodeExecutionResult ChildResult = ChildNodes[CurrentNodeIndex].UpdateActiveNodes(Component);
        if(ChildNodes[CurrentNodeIndex].IsEnabled())
        {
            // Node is enabled. We are done
            bHasEnabledChild = true;
            Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
            return Result;
        }

        // We used to have an enabled child node, but now we don't. We need to reset the current node index and try again
        CurrentNodeIndex = 0;
        bHasEnabledChild = false;
        for (int i = 0; i < ChildNodes.Num(); i++)
        { 
            ChildResult = ChildNodes[i].UpdateActiveNodes(Component);
            if(ChildNodes[i].IsEnabled())
            {
                // Node is enabled. We are done
                bHasEnabledChild = true;
                Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
                CurrentNodeIndex = i; 
                break;
            }
        }
        
        return Result;  
    }

    void AbortFromParent() override
    {
        Super::AbortFromParent();
        
        if(IsEnabled() == false)
        {
            return;
        }

        bHasEnabledChild = false;
        CurrentNodeIndex = 0;

        for (UCapabilityNode_AS ChildNode : ChildNodes)
        {
            if (ChildNode.IsEnabled())
            {
                ChildNode.AbortFromParent();
            }
        }
    }
    
#ifdef IMGUI
    void ShowImGui() override
    {
        Super::ShowImGui();
        
        FImGuiScopedID ScopedID;
        FColor Color = IsEnabled() ? JesterColors::Dracula::Green : JesterColors::Dracula::Red;
        ImGui::PushStyleColor(EImGuiCol::Text, Color);
        ImGui::Text("-- State");
        ImGui::PopStyleColor();
        for (int i = 0; i < ChildNodes.Num(); i++)
        {
            ChildNodes[i].ShowImGui();
        }
    }
#endif
}