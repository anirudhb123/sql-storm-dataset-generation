WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN V.CreationDate END), 0) AS LastUpvoteDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN V.CreationDate END), 0) AS LastDownvoteDate
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        P.LastActivityDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.Upvotes,
        U.Downvotes,
        P.PostCount,
        P.QuestionCount,
        P.AnswerCount,
        P.TotalViews,
        P.AverageScore,
        P.LastActivityDate
    FROM UserScore U 
    JOIN PostStats P ON U.UserId = P.OwnerUserId
),
HighActivityUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY (PostCount + QuestionCount + AnswerCount) DESC) AS Rank
    FROM CombinedStats
    WHERE LastActivityDate IS NOT NULL
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        AverageScore,
        Rank,
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation User'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Mid Reputation User'
            ELSE 'Low Reputation User' 
        END AS ReputationTier
    FROM HighActivityUsers
    WHERE Rank <= 10
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    Upvotes,
    Downvotes,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    AverageScore,
    ReputationTier,
    CASE 
        WHEN Upvotes = 0 AND Downvotes = 0 THEN 'No Voting Activity'
        WHEN Upvotes > Downvotes THEN 'Positive Voting Activity'
        ELSE 'Negative Voting Activity'
    END AS VotingActivity,
    NULLIF(LastActivityDate, '1970-01-01 00:00:00') AS LastActivity (an example of handling NULL)
FROM FilteredUsers
ORDER BY Reputation DESC, PostCount DESC;
