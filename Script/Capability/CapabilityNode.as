/**
 * Result structure returned by capability node execution
 * Contains the list of capabilities that should be active after node evaluation
 */
struct FCapabilityNodeExecutionResult
{
    /** Array of capabilities that should be enabled after this node's execution */
    TArray<UCapability_AS> EnabledCapabilities;
}

/**
 * Abstract base class for capability tree nodes
 * 
 * Capability nodes form a tree structure that determines which capabilities should be active.
 * Different node types implement different logic (parallel, sequence, first-valid, etc.)
 * 
 * Node Types:
 * - Leaf Node: Contains a single capability
 * - Parallel Node: Runs all children simultaneously  
 * - Sequence Node: Runs children in order until one fails
 * - First Valid Node: Runs the first child that can be enabled
 */
UCLASS(Abstract)
class UCapabilityNode_AS : UObject
{
    /**
     * Checks if this node is currently enabled
     * @return True if the node is active
     */
    bool IsEnabled() const
    {
        return true;
    }

    /** Reference to parent node in the capability tree */
    UCapabilityNode_AS ParentNode;

    /**
     * Updates this node and returns which capabilities should be active
     * Must be implemented by derived classes to define node behavior
     * 
     * @param Component The capability system component managing this tree
     * @return Result containing enabled capabilities
     */
    FCapabilityNodeExecutionResult UpdateActiveNodes(UCapabilitySystemComponent_AS Component)
    {
        check(false, "UpdateActiveNodes not implemented in base class");
        return FCapabilityNodeExecutionResult();
    }

    /**
     * Called when the parent node wants to abort this node's execution
     * Override to implement cleanup logic when node is forcibly stopped
     */
    void AbortFromParent()
    {

    }

    /**
     * Debug method for displaying node information in ImGui
     * Override to show node-specific debug information
     */
#ifdef IMGUI
    void ShowImGui()
    {

    }
#endif
   
}