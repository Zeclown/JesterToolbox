/**
 * First Valid node that tries child nodes in order until one succeeds
 * 
 * Evaluates children sequentially and activates the first one that can be enabled.
 * Unlike sequence nodes, this doesn't require previous steps to complete.
 * If no current child is enabled, it tries all children from the beginning.
 * 
 * Usage Example:
 * ```
 * // Create a movement priority system
 * UCompoundFirstValidNode_AS MovementPriority = UCompoundFirstValidNode_AS();
 * MovementPriority.Or(SprintCapability)    // Prefer sprinting
 *                 .Or(WalkCapability)      // Fall back to walking  
 *                 .Or(CrawlCapability);    // Last resort: crawling
 * // Will use the first available movement type
 * ```
 */
class UCompoundFirstValidNode_AS : UCapabilityNode_AS
{
    /** Array of child nodes to evaluate in priority order */
    TArray<UCapabilityNode_AS> ChildNodes;
    
    /** Index of the currently enabled child node */
    int CurrentNodeIndex = 0;
    
    /** True if a child node is currently enabled */
    bool bCurrentNodeIsEnabled = false;

    /**
     * Returns true if any child node is currently enabled
     * @return True if a child is active
     */
    bool IsEnabled() const override
    {
        return bCurrentNodeIsEnabled;
    }

    /**
     * Adds a child node as an alternative option
     * @param Node The node to add as an option
     * @return This node for method chaining
     */
    UCompoundFirstValidNode_AS Or(UCapabilityNode_AS Node)
    {
        Node.ParentNode = this;
        ChildNodes.Add(Node);
        return this;
    }

    /**
     * Convenience method to add a capability class as an alternative
     * @param CapabilityClass The capability class to add as an option
     * @return This node for method chaining
     */
    UCompoundFirstValidNode_AS Or(TSubclassOf<UCapability_AS> CapabilityClass)
    {
        UCapability_AS Capability = Cast<UCapability_AS>(NewObject(this, CapabilityClass));
        return Or(Capability.GenerateCompoundNode());
    }

    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component) override
    {
        bCurrentNodeIsEnabled = false;
        FCapabilityNodeExecutionResult Result;
        Result.EnabledCapabilities.Empty();
        if(ChildNodes.Num() == 0)
        {
            return Result;
        }   

        int PreviousNodeIndex = CurrentNodeIndex;

        for (int i = 0; i < ChildNodes.Num(); i++)
        { 
            FCapabilityNodeExecutionResult ChildResult = ChildNodes[i].UpdateActiveNodes(Component);
            if(ChildNodes[i].IsEnabled())
            {
                // Node is enabled. We are done
                bCurrentNodeIsEnabled = true;
                Result.EnabledCapabilities.Append(ChildResult.EnabledCapabilities);
                CurrentNodeIndex = i; 
                break;
            }
        }

        if(PreviousNodeIndex != CurrentNodeIndex)
        {
            // We changed the current node index. We need to reset the previous node
            if(PreviousNodeIndex < ChildNodes.Num())
            {
                ChildNodes[PreviousNodeIndex].AbortFromParent();
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

        CurrentNodeIndex = 0;
        bCurrentNodeIsEnabled = false;

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
        FColor Color = IsEnabled() ? RaveColors::Dracula::Green : RaveColors::Dracula::Red;
        ImGui::PushStyleColor(EImGuiCol::Text, Color);
        ImGui::Text("-- First Valid");
        ImGui::PopStyleColor();
        for (int i = 0; i < ChildNodes.Num(); i++)
        {
            ChildNodes[i].ShowImGui();
        }
    }
#endif
}