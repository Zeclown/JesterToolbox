enum EJesterLogVerbosity
{
	Log,
	Verbose,
	VeryVerbose,
	MAX
}

namespace JesterLog
{
    FString VerbosityToString(const EJesterLogVerbosity Verbosity)
    {
        switch (Verbosity)
        {
            case EJesterLogVerbosity::VeryVerbose:
                return "VeryVerbose";
            case EJesterLogVerbosity::Verbose:
                return "Verbose";
            case EJesterLogVerbosity::Log:
                return "Log";
            default:
                return "Unknown";
        }
    } 
}


// Helper that keeps track of the last N log messages so they can be recalled later.
struct FLogHistory
{
	FLogHistory()
	{
	}

	FLogHistory(bool InAppendServerTimestamp, bool InAppendASFunction, bool InEnabled, bool InSendToLog = false, FName InLogCategory = n"", int32 InMaxHistory = 50)
	{
		MaxHistory = InMaxHistory;
		bAppendTimestamp = InAppendServerTimestamp;
		bAppendASFunction = InAppendASFunction;
		bSendToLog = InSendToLog;
		LogCategory = InLogCategory;
		bEnabled = InEnabled;
	}

	bool bAppendTimestamp = false;
	bool bAppendASFunction = false;
	bool bSendToLog = false;
	FName LogCategory;
	bool bEnabled = true;

	// Circular buffer to store the last N log messages.
	private TArray<FString> LogHistory;
	private int32 MaxHistory = 50;
	private int Idx = 0;

	private bool bDirty = false;

	TArray<FString> OrderedLogHistory;

	void AddLog(FString LogMessage, EJesterLogVerbosity LogVerbosity = EJesterLogVerbosity::Log)
	{
		if (!bEnabled)
		{
			return;
		}

		if (UJesterLogManager_AS::Get() != nullptr && UJesterLogManager_AS::Get().IsLogVerbosityAtLeast(LogCategory, LogVerbosity) == false)
		{
			return;
		}

		FString FinalLogMessage = GenerateLog(LogMessage);
		AppendToLogHistory(FinalLogMessage);

		if (bSendToLog)
		{
			Log(LogCategory, FinalLogMessage);
		}
	}

	void AddWarning(FString LogMessage)
	{
		FString FinalLogMessage = GenerateLog(LogMessage);
		Warning(LogCategory, LogMessage);

		if (bEnabled)
		{
			AppendToLogHistory("Warning: " + FinalLogMessage);
		}
	}

	void AddError(FString LogMessage)
	{
		FString FinalLogMessage = GenerateLog(LogMessage);
		Error(LogCategory, LogMessage);

		if (bEnabled)
		{
			AppendToLogHistory("Error: " + FinalLogMessage);
		}
	}

	private void AppendToLogHistory(FString Log)
	{
		// Marks it as dirty so that when something tries to read the log history, it will be updated.
		bDirty = true;
		if (LogHistory.Num() < MaxHistory)
		{
			LogHistory.Add(Log);
		}
		else
		{
			LogHistory[Idx] = Log;
			Idx = (Idx + 1) % MaxHistory;
		}
	}

	private FString GenerateLog(FString LogMessage)
	{
		FString Timestamp = "";
		if (bAppendTimestamp)
		{
			Timestamp = Jester::TimeDurationToText(System::GetGameTimeInSeconds()).ToString() + " - ";
		}

		FString ASFunction = "";
		if (bAppendASFunction)
		{
			ASFunction = Jester::GetASCurrentFunctionName() + " - ";
		}
		return Timestamp + ASFunction + LogMessage;
	}

	// Get the last N log messages.
	TArray<FString> GatherLogHistory()
	{
		if (!bDirty)
		{
			return OrderedLogHistory;
		}

		bDirty = false;
		OrderedLogHistory.Empty();
		for (int i = 0; i < LogHistory.Num(); i++)
		{
			OrderedLogHistory.Add(LogHistory[(Idx + i) % MaxHistory]);
		}
		return OrderedLogHistory;
	}

	// Clear the log history.
	void ClearLogHistory()
	{
		LogHistory.Empty();
		OrderedLogHistory.Empty();
		Idx = 0;
		bDirty = false;
	}

#ifdef IMGUI
	void ShowImGui(FString Label, FVector2f OptionalSize = FVector2f(0, 100))
	{
		if (ImGui::Button("Clear", FVector2f(50, 20)))
		{
			ClearLogHistory();
		}
		ImGui::SameLine();
		if (ImGui::Button("Copy", FVector2f(50, 20)))
		{
			FString LogString = "";
			for (FString Log : GatherLogHistory())
			{
				LogString += Log + "\n";
			}
			Jester::CopyToClipboard(LogString);
		}
		ImGui::BeginChild(Label, OptionalSize, true, EImGuiWindowFlags::AlwaysVerticalScrollbar);
		TArray<FString> Logs = GatherLogHistory();
		int i = 0;
		for (FString Log : Logs)
		{
			ImGui::Text(Log);
		}
		ImGui::EndChild();
	}
#endif

	void DumpLogHistory(FName Category)
	{
		TArray<FString> Logs = GatherLogHistory();
		for (FString EachLog : Logs)
		{
			Log(Category, EachLog);
		}
	}
}