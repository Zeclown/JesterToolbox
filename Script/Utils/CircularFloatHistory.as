/**
 * Configuration settings for ImGui plotting of circular float history
 */
namespace FCircularFloatHistory
{
	/**
	 * Settings structure for customizing ImGui plot appearance
	 */
	struct FShowImGuiSettings
	{
		/** Default constructor with sensible defaults */
		FShowImGuiSettings()
		{
			// Empty constructor
		}

		/** Size of the plot widget in pixels */
		FVector2f Size = FVector2f(500, 200);

		/** Label for the X-axis */
		FString XLabel = "X";
		
		/** Label for the Y-axis */
		FString YLabel = "Y";

		/** Y-axis limits (0,0 means auto-scale) */
		FVector2f YAxisLimits = FVector2f(0, 0);

		// Future axis configuration options
		// EImPlotAxisFlags YAxisFlags;
		// EImPlotAxisFlags XAxisFlags;
	};
}

/**
 * Circular buffer for storing float values with efficient access patterns
 * 
 * This structure maintains a fixed-size buffer of float values that wraps around
 * when full. Useful for tracking recent history of numeric values like frame times,
 * movement speeds, or any other time-series data.
 * 
 * Features:
 * - Fixed memory footprint
 * - Efficient insertion and access
 * - ImGui plotting support
 * - Ordered value retrieval
 * 
 * Usage Example:
 * ```
 * FCircularFloatHistory FrameTimeHistory(60); // Track last 60 frame times
 * 
 * // Add values each frame
 * FrameTimeHistory.Add(DeltaTime);
 * 
 * // Get recent values
 * float newestTime = FrameTimeHistory.GetNewest();
 * float oldestTime = FrameTimeHistory.GetOldest();
 * TArray<float> allTimes = FrameTimeHistory.GetAll();
 * 
 * // Show in ImGui
 * FCircularFloatHistory::FShowImGuiSettings PlotSettings;
 * PlotSettings.YLabel = "Frame Time (ms)";
 * FrameTimeHistory.ShowImGui("Frame Times", PlotSettings);
 * ```
 */
struct FCircularFloatHistory
{
	/** The actual circular buffer of float values */
	UPROPERTY()
	TArray<float> Values;
	
	/** Cached array of values in chronological order (oldest to newest) */
	TArray<float> CachedAllValuesOrdered;

	/** Current write position in the circular buffer */
	UPROPERTY()
	int CurrentIndex = 0;

	/** Imgui plot requires a list of x values. We can cache them here to avoid recalculating them every frame. Turn off if you don't plan to use ImGui.*/
	bool bAutoPrepareImGui = false;

	/** Flag indicating if cached ordered values need to be regenerated */
	bool bDirty = false;

	/** True if the buffer has wrapped around at least once */
	bool bLooped = false;

	/** Cached X-axis values for ImGui plotting (indices) */
	TArray<float> CachedImGuiXValues;

	/** ImPlot flags for X-axis configuration */
	int ImPlotXFlags = 0;
	
	/** ImPlot flags for Y-axis configuration */
	int ImPlotYFlags = 0;

	/**
	 * Constructor to create a circular float history with specified size
	 * 
	 * @param Size Number of float values to store in the circular buffer
	 * @param ShouldAutoPrepareImGui Whether to automatically prepare data for ImGui plotting
	 */
	FCircularFloatHistory(int Size, bool ShouldAutoPrepareImGui = true)
	{
		Values.SetNum(Size);
		CachedAllValuesOrdered.SetNum(Size);
		for (int i = 0; i < Size; i++)
		{
			Values[i] = 0;
		}

		bAutoPrepareImGui = ShouldAutoPrepareImGui;
		if (ShouldAutoPrepareImGui)
		{
			CachedImGuiXValues.SetNum(Size);
			for (int i = 0; i < Size; i++)
			{
				CachedImGuiXValues[i] = i;
			}
		}
	}

	/**
	 * Adds a new float value to the circular buffer
	 * 
	 * @param Value The float value to add to the history
	 */
	void Add(float Value)
	{
		Values[CurrentIndex] = Value;
		CurrentIndex = (CurrentIndex + 1) % Values.Num();
		bDirty = true;
		if (CurrentIndex == 0)
		{
			bLooped = true;
		}
	}

	/**
	 * Clears all values in the buffer, setting them to zero
	 */
	void Clear()
	{
		for (int i = 0; i < Values.Num(); i++)
		{
			Values[i] = 0;
		}
		bDirty = true;
	}

	/**
	 * Gets a value at a specific index in chronological order
	 * 
	 * Index 0 is the oldest value, higher indices are newer.
	 * Negative indices count from the end (-1 is newest).
	 * 
	 * @param Index The chronological index to retrieve
	 * @return The float value at that index
	 */
	float Get(int Index)
	{
		int RealIndex = Index;
		if (Index < 0)
		{
			RealIndex = Values.Num() + Index;
		}

		if (bLooped)
		{
			return Values[(CurrentIndex + RealIndex) % Values.Num()];
		}
		else
		{
			return Values[RealIndex];
		}
	}

	float GetOldest()
	{
		return Get(0);
	}

	float GetNewest()
	{
		return Get(CurrentIndex - 1);
	}

	TArray<float> GetAll()
	{
		if (bDirty)
		{
			for (int i = 0; i < Values.Num(); i++)
			{
				CachedAllValuesOrdered[i] = Get(i);
			}
			bDirty = false;
		}
		return CachedAllValuesOrdered;
	}

#ifdef IMGUI
	/**
	 * Displays the circular float history as a plot in ImGui
	 * 
	 * Creates an interactive plot showing the historical float values over time.
	 * Includes a clear button and configurable plot appearance.
	 * 
	 * @param Label The label for the plot widget
	 * @param Settings Configuration for plot appearance and behavior
	 */
	void ShowImGui(FString Label, FCircularFloatHistory::FShowImGuiSettings Settings)
	{
		ImGui::BeginGroup();

		FImGuiScopedID(Label);
		TArray<float> AllValues = GetAll();

		if (ImGui::Button("Clear", FVector2f(100, 20)))
		{
			Clear();
		}
		if (ImPlot::BeginPlot(Label, Settings.Size))
		{
			ImPlot::SetupAxis(EImAxis::X1, Settings.XLabel, EImPlotAxisFlags::AutoFit);
			ImPlot::SetupAxis(EImAxis::Y1, Settings.YLabel, EImPlotAxisFlags::AutoFit);

			if (Settings.YAxisLimits.X != 0 || Settings.YAxisLimits.Y != 0)
			{
				ImPlot::SetNextAxisLimits(EImAxis::Y1, Settings.YAxisLimits.X, Settings.YAxisLimits.Y);
			}
			int XLimit = bLooped ? CachedImGuiXValues.Num() : CurrentIndex;
			TArray<FVector2f> ValuePairs;
			ValuePairs.SetNum(XLimit);
			for (int i = 0; i < XLimit; i++)
			{
				ValuePairs[i] = FVector2f(float32(CachedImGuiXValues[i]), float32(AllValues[i]));
			}

			ImPlot::PlotLine(f"Values###{Label}Values", ValuePairs);
			ImPlot::EndPlot();
		}
		ImGui::EndGroup();
	}
#endif
};