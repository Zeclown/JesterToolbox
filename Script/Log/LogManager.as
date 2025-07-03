namespace JesterLog
{
	UFUNCTION(NotBlueprintCallable)
	void Cmd_SetLogVerbosity(TArray<FString> Args)
	{
		if (Args.Num() < 2)
		{
			Error("Usage: Cult.SetLogVerbosity <LogCategory> <Verbosity>");
			return;
		}

		FName LogCategory = FName(Args[0]);
		EJesterLogVerbosity Verbosity = EJesterLogVerbosity::Log;
		for (int i = 0; i < int(EJesterLogVerbosity::MAX); i++)
		{
			if (JesterLog::VerbosityToString(EJesterLogVerbosity(i)) == Args[1])
			{
				Verbosity = EJesterLogVerbosity(i);
				break;
			}
		}

		SetLogVerbosity(LogCategory, Verbosity);
	}

	const FConsoleCommand Cmd_SetLogVerbosity("SetLogVerbosity", n"JesterLog::Cmd_SetLogVerbosity");

	void SetLogVerbosity(FName Log, EJesterLogVerbosity Verbosity)
	{
		UJesterLogManager_AS CultLogManager = UJesterLogManager_AS::Get();
		CultLogManager.SetLogVerbosity(Log, Verbosity);
	}
}

class UJesterLogManager_AS : UScriptEngineSubsystem
{
	private TMap<FName, EJesterLogVerbosity> LogVerbosity;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{

	}

    void InitLogVerbosity(TMap<FName, EJesterLogVerbosity> DefaultLogVerbosity)
    {
		for (auto Pair : DefaultLogVerbosity)
		{
			SetLogVerbosity(Pair.Key, Pair.Value);
		}
    }

	EJesterLogVerbosity GetLogVerbosity(FName Log)
	{
		if (LogVerbosity.Contains(Log))
		{
			return LogVerbosity[Log];
		}
		return EJesterLogVerbosity::Log;
	}

	bool IsLogVerbosityAtLeast(FName Log, EJesterLogVerbosity Verbosity)
	{
		if (LogVerbosity.Contains(Log))
		{
			return LogVerbosity[Log] >= Verbosity;
		}
		return Verbosity <= EJesterLogVerbosity::Log; // Default to Log if not set
	}

	void SetLogVerbosity(FName LogCategory, EJesterLogVerbosity Verbosity)
	{
		LogVerbosity.Add(LogCategory, Verbosity);
		Log(f"Set log verbosity for {LogCategory} to {Verbosity}");
	}
}