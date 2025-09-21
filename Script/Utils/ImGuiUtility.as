#ifdef IMGUI
namespace ImGui
{
	// Helps with boilerplate code for ImGui::Text setting a color based on a bool value. If TrueString is empty, it will color the label instead
	bool BoolText(const FString& Label, bool Value, FString TrueString = "True", FString FalseString = "False")
	{
		if (TrueString.IsEmpty())
		{
			// If its empty, it means the label needs to be colored
			if (Value)
			{
				ImGui::PushStyleColor(EImGuiCol::Text, JesterColors::Dracula::Green);
			}
			else
			{
				ImGui::PushStyleColor(EImGuiCol::Text, JesterColors::Dracula::Red);
			}
			ImGui::Text(f"{Label}");
			ImGui::PopStyleColor();
			return Value;
		}

		ImGui::Text(f"{Label}: ");
		if (Value)
		{
			ImGui::PushStyleColor(EImGuiCol::Text, JesterColors::Dracula::Green);
		}
		else
		{
			ImGui::PushStyleColor(EImGuiCol::Text, JesterColors::Dracula::Red);
		}
		ImGui::SameLine();
		ImGui::Text(f"{Value ? TrueString : FalseString}");
		ImGui::PopStyleColor();
		return Value;
	}
}
#endif