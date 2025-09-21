/**
 * JesterColors namespace provides color constants used throughout the JesterToolbox plugin
 * Includes themed color palettes for UI, visual effects, and debugging
 */
namespace JesterColors
{
    /**
     * Dracula theme color palette
     * Provides a dark, high-contrast color scheme popular in development environments
     */
    namespace Dracula
	{
		const FColor Green = FColor(80, 250, 123, 255);
		const FColor Pink = FColor(255, 121, 198, 255);
		const FColor Red = FColor(255, 85, 85, 255);
		const FColor DarkGrey = FColor(44, 42, 55, 255);
		const FColor LightGrey = FColor(68, 71, 90, 255);
		const FColor Purple = FColor(189, 147, 249, 255);
		const FColor Orange = FColor(255, 184, 108, 255);
		const FColor Yellow = FColor(241, 250, 140, 255);
	}

    /**
     * Core toolbox color palette
     * Contains the primary colors used in the JesterToolbox visual design
     */
    namespace Core
    {
        const FLinearColor Background = FLinearColor(0.176, 0, 0.231);
        const FLinearColor BackgroundSecondary = FLinearColor(0.204, 0.204, 0.290);
		const FLinearColor Primary = FLinearColor(0.000, 1.000, 1.000);
		const FLinearColor Secondary = FLinearColor(1.000, 0.078, 0.576);
		const FLinearColor Warning = FLinearColor(0.78, 1.00, 0.00);
		const FLinearColor Alert = FLinearColor(1.000, 0.843, 0.000);
    }
}