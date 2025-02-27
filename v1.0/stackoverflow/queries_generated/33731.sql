WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id, 
        U.Reputation, 
        COALESCE(BadgeCounts.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) AS BadgeCounts ON U.Id = BadgeCounts.UserId
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COUNT(CM.Id) AS CommentCount
    FROM Users U
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN Comments CM ON U.Id = CM.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, PS.QuestionCount, PS.AnswerCount, PS.TotalScore
),
FinalStats AS (
    SELECT 
        UR.Id AS UserId,
        UR.Reputation,
        UR.BadgeCount,
        UA.DisplayName,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.TotalScore,
        UA.CommentCount,
        ROW_NUMBER() OVER (ORDER BY UA.TotalScore DESC) AS Rank,
        CASE 
            WHEN UR.Reputation >= 1000 THEN 'High'
            WHEN UR.Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM UserReputation UR
    JOIN UserActivity UA ON UR.Id = UA.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    CommentCount,
    Rank,
    ReputationCategory
FROM FinalStats
WHERE BadgeCount > 0 
ORDER BY Rank, DisplayName;

-- Aggregate statistic of posts and correlated badge counts.
SELECT 
    U.DisplayName, 
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN Comments C ON P.Id = C.PostId
GROUP BY U.DisplayName
HAVING COUNT(DISTINCT P.Id) > 10
ORDER BY TotalPosts DESC;

-- Comparatively join Post and Comment stats with comparison to Badges held
SELECT 
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS Posts,
    COUNT(DISTINCT C.Id) AS Comments,
    COUNT(DISTINCT B.Id) AS Badges,
    AVG(P.Score) AS AvgPostScore,
    MAX(V.CreationDate) AS LastVoteDate,
    MIN(P.CreationDate) AS FirstPostDate
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Badges B ON U.Id = B.UserId
LEFT JOIN Votes V ON P.Id = V.PostId
GROUP BY U.DisplayName
ORDER BY AvgPostScore DESC, Posts DESC;

-- Cross-join to merge multiple metrics for debugging and performance benchmarking
SELECT 
    RANK() OVER (PARTITION BY UA.ReputationCategory ORDER BY UA.TotalScore DESC) AS ReputationRank,
    UA.DisplayName,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.CommentCount,
    UA.TotalScore,
    UR.BadgeCount,
    P.Title AS LatestPostTitle,
    P.CreationDate AS LatestPostDate
FROM UserActivity UA
LEFT JOIN Posts P ON UA.UserId = P.OwnerUserId
INNER JOIN UserReputation UR ON UA.UserId = UR.Id
WHERE RANK() OVER (ORDER BY UA.TotalScore DESC) <= 10
ORDER BY UR.BadgeCount DESC;
