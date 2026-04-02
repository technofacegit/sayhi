/// One icebreaker prompt from [icebreaker_questions] (Supabase).
class IcebreakerQuestion {
  const IcebreakerQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<String> options;
}
