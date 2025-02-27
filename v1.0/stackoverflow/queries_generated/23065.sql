WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId = 2 THEN V.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId = 3 THEN V.Id END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS LatestActivity
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
FilteredUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalQuestionScore,
        QuestionCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount
    FROM 
        UserActivity
    WHERE 
        LatestActivity = 1 AND Reputation > 100
),
HighScoringUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        (TotalQuestionScore + UpvoteCount * 2 - DownvoteCount) AS FinalScore
    FROM 
        FilteredUsers
    WHERE 
        QuestionCount > 5
    ORDER BY 
        FinalScore DESC
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation AS OriginalReputation,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    U.FinalScore 
FROM 
    HighScoringUsers U
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount 
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON U.UserId = B.UserId
WHERE 
    U.FinalScore > 50
ORDER BY 
    U.FinalScore DESC, 
    U.DisplayName ASC
OPTION (RECOMPILE);

This SQL query includes:

- Common Table Expressions (CTEs) for breaking down the query into logical stages: user activity, filtering for users with significant interaction, and calculating a final score based on reputation and activity.
- Various aggregations and calculations, including total question score, upvotes, and downvotes.
- Filtering using `WHERE`, `HAVING` clauses, and `COALESCE` to handle NULLs.
- The use of a compound score calculation with complicated predicates.
- Outer join to gather additional badge information, demonstrating a join with a derived table.
- Ordered results by final score and display name.
- Utilization of `OPTION (RECOMPILE)` which is an obscure semantic, often used for query performance benefits by optimizing execution plans.
