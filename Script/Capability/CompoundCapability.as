
class UCompoundCapability_AS : UCapability_AS
{
    UCapabilityNode_AS GenerateCompoundNode() override
    {
       check(false, "GenerateCompound not implemented in base class");
       return UCapabilityNode_AS();
    }
}