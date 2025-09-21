/**
 * Sequence node that executes child nodes in order until one fails
 * 
 * Children are executed sequentially. If a child fails to enable, the sequence
 * stops and resets. If a child was enabled but becomes disabled, the sequence
 * moves to the next child.
 * 
 * Usage Example:
 * ```
 * // Create a combo sequence: crouch -> aim -> shoot
 * UCompoundSequence_AS ComboSequence = UCompoundSequence_AS();
 * ComboSequence.Then(CrouchCapability)   // Must crouch first
 *              .Then(AimCapability)      // Then aim
 *              .Then(ShootCapability);   // Finally shoot
 * // Each step must complete before the next can begin
 * ```
 */
class UCompoundSequence_AS : UCapabilityNode_AS
{
    /** Array of child nodes to execute in sequence */
    TArray<UCapabilityNode_AS> ChildNodes;
    
    /** Index of the currently executing child node */
    int CurrentNodeIndex = 0;
    
    /** True if the current node was enabled in the last update */
    bool bCurrentNodeWasEnabled = false;

    /**
     * Returns true if the current node in the sequence is enabled
     * @return True if the sequence is currently active
     */
    bool IsEnabled() const override
    {
        return bCurrentNodeWasEnabled;
    }

    /**
     * Adds a child node to the sequence
     * @param Node The node to add as the next step in the sequence
     * @return This node for method chaining
     */
    UCompoundSequence_AS Then(UCapabilityNode_AS Node)
    {
        Node.ParentNode = this;
        ChildNodes.Add(Node);
        return this;
    }

    /**
     * Convenience method to add a capability class as the next sequence step
     * @param CapabilityClass The capability class to add to the sequence
     * @return This node for method chaining
     */
    UCompoundSequence_AS Then(TSubclassOf<UCapability_AS> CapabilityClass)
    {
        UCapability_AS Capability = NewObject(this, CapabilityClass);
        return Then(Capability.GenerateCompoundNode());
    }

    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component) override
    {
        FCapabilityNodeExecutionResult Result;
        Result.EnabledCapabilities.Empty();
        if(ChildNodes.Num() == 0)
        {
            return Result;
        }   

        for (int i = CurrentNodeIndex; i < ChildNodes.Num(); i++)
        { 
            FCapabilityNodeExecutionResult ChildResult = ChildNodes[i].UpdateActiveNodes(Component);
            if(bCurrentNodeWasEnabled)
            {
                if(ChildNodes[i].IsEnabled() == false)
                {
                    // Node was enabled but is now disabled. Skip to next node
                    CurrentNodeIndex++;
                    bCurrentNodeWasEnabled = false;
                    Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
                    continue;
                }

                //Node is still enabled. We are still in the same node
                break;
            }

            if(ChildNodes[i].IsEnabled() == false)
            {
                // We tried to enable a node but it failed. We need to skip to fail the sequence
                CurrentNodeIndex = 0;
                bCurrentNodeWasEnabled = false;
                Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
                break;
            }

            // Node is enabled. We are done
            bCurrentNodeWasEnabled = true;
            Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
            break;

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

        bCurrentNodeWasEnabled = false;
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
        FColor Color = IsEnabled() ? JesterColors::Green : JesterColors::Red;
        ImGui::PushStyleColor(EImGuiCol::Text, Color);
        ImGui::Text("-- Sequence");
        ImGui::PopStyleColor();
        for (int i = 0; i < ChildNodes.Num(); i++)
        {
            ChildNodes[i].ShowImGui();
        }
    }
#endif
}