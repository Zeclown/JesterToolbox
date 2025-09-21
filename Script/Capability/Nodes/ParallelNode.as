/**
 * Parallel node that executes all child nodes simultaneously
 * 
 * This node is considered enabled if ANY of its children are enabled.
 * All children are updated every frame regardless of their state.
 * 
 * Usage Example:
 * ```
 * // Create a parallel node that allows multiple abilities at once
 * UParallelSequence_AS ParallelNode = UParallelSequence_AS();
 * ParallelNode.Do(MovementCapability);  // Can move
 * ParallelNode.Do(LookCapability);      // Can look around  
 * ParallelNode.Do(JumpCapability);      // Can jump
 * // All three can be active simultaneously
 * ```
 */
class UParallelSequence_AS : UCapabilityNode_AS
{
    /** Array of child nodes to execute in parallel */
    TArray<UCapabilityNode_AS> ChildNodes;

    /** True if any child node is currently enabled */
    bool bAnyNodeWasEnabled = false;

    /**
     * Returns true if any child node is enabled
     * @return True if at least one child is active
     */
    bool IsEnabled() const override
    {
        return bAnyNodeWasEnabled;
    }

    /**
     * Adds a child node to be executed in parallel
     * @param Node The node to add as a child
     * @return This node for method chaining
     */
    UParallelSequence_AS Do(UCapabilityNode_AS Node)
    {
        Node.ParentNode = this;
        ChildNodes.Add(Node);
        return this;
    }

    /**
     * Convenience method to add a capability class as a child node
     * @param CapabilityClass The capability class to add
     * @return This node for method chaining
     */
    UParallelSequence_AS Do(TSubclassOf<UCapability_AS> CapabilityClass)
    {
        UCapability_AS Capability = NewObject(this, CapabilityClass);
        return Do(Capability.GenerateCompoundNode());
    }

    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component) override
    {
        FCapabilityNodeExecutionResult Result;
        Result.EnabledCapabilities.Empty();
        for (UCapabilityNode_AS ChildNode : ChildNodes)
        {
            FCapabilityNodeExecutionResult ChildResult = ChildNode.UpdateActiveNodes(Component);
            if (ChildNode.IsEnabled())
            {
                bAnyNodeWasEnabled = true;
                Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
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

        bAnyNodeWasEnabled = false;

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
        FColor Color = IsEnabled() ? JesterColors::Green : JesterColors::Red;
        ImGui::PushStyleColor(EImGuiCol::Text, Color);
        ImGui::Text("-- Parallel");
        ImGui::PopStyleColor();
        for (int i = 0; i < ChildNodes.Num(); i++)
        {
            ChildNodes[i].ShowImGui();
        }
    }
#endif

}