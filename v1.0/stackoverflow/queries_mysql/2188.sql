
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        @row_number := @row_number + 1 AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    CROSS JOIN 
        (SELECT @row_number := 0) AS r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    U.TotalBadges,
    U.ReputationRank,
    COALESCE(PA.PostCount, 0) AS TotalPosts,
    COALESCE(PA.AcceptedAnswers, 0) AS TotalAcceptedAnswers,
    COALESCE(PA.AvgScore, 0) AS AverageScore
FROM 
    UserStatistics U
LEFT JOIN 
    PostActivity PA ON U.UserId = PA.OwnerUserId
WHERE 
    U.Reputation > (
        SELECT AVG(Reputation) FROM UserStatistics
    ) AND 
    (U.Views IS NULL OR U.Views > 1000) 
ORDER BY 
    U.Reputation DESC, 
    U.Views DESC
LIMIT 100;
