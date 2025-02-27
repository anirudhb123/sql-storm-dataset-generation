WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UA.*,
        DENSE_RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity UA
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.QuestionCount,
    RU.AnswerCount,
    COALESCE(RU.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN RU.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN RU.ReputationRank <= 50 THEN 'Active Contributor'
        ELSE 'Novice Contributor'
    END AS ContributionLevel
FROM 
    RankedUsers RU
WHERE 
    RU.QuestionCount > 5
    AND RU.AnswerCount > 10
ORDER BY 
    RU.Reputation DESC
LIMIT 20;

WITH RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS RecentPostCount,
        AVG(P.Score) AS AvgPostScore,
        MAX(P.CreationDate) AS MostRecentPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId
),
UserStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        R.Reputation,
        R.ReputationRank,
        R.TotalPosts,
        R.QuestionCount,
        R.AnswerCount,
        R.TotalBounty,
        COALESCE(RPS.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(RPS.AvgPostScore, 0) AS AvgPostScore,
        COALESCE(RPS.MostRecentPostDate, '1900-01-01') AS MostRecentPostDate
    FROM 
        RankedUsers R
    LEFT JOIN 
        RecentPostStats RPS ON R.UserId = RPS.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.ReputationRank,
    US.TotalPosts,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalBounty,
    US.RecentPostCount,
    US.AvgPostScore,
    US.MostRecentPostDate,
    CASE 
        WHEN US.RecentPostCount >= 5 AND US.AvgPostScore >= 3 THEN 'Active'
        ELSE 'Inactive'
    END AS ActiveStatus
FROM 
    UserStats US
WHERE 
    US.Reputation > 0
ORDER BY 
    US.Reputation DESC
LIMIT 50;
