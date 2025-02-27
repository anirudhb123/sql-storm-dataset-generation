WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High' 
            WHEN U.Reputation >= 500 THEN 'Medium' 
            ELSE 'Low' 
        END AS ReputationLevel
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.DisplayName,
        UR.ReputationLevel,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.AvgScore
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
    JOIN Users U ON UR.UserId = U.Id
),
TopContributors AS (
    SELECT 
        UserPostStats.*, 
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM UserPostStats
    WHERE TotalPosts IS NOT NULL
)
SELECT 
    U.DisplayName,
    U.ReputationLevel,
    U.TotalPosts,
    COALESCE(U.Questions, 0) AS Questions,
    COALESCE(U.Answers, 0) AS Answers,
    U.AvgScore,
    COALESCE(COUNT(DISTINCT C.Id), 0) AS TotalComments,
    NULLIF(AVG(V.BountyAmount), 0) AS AvgBounty
FROM TopContributors U
LEFT JOIN Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
WHERE U.Rank <= 10
GROUP BY U.DisplayName, U.ReputationLevel, U.TotalPosts, U.Questions, U.Answers, U.AvgScore
ORDER BY U.TotalPosts DESC;
