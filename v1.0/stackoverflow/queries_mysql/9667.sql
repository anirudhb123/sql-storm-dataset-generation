
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        TotalPosts,
        TotalScore,
        @row_number := IF(@prev_total_score = TotalScore, @row_number, @row_number + 1) AS ScoreRank,
        @prev_total_score := TotalScore
    FROM UserVoteStats, (SELECT @row_number := 0, @prev_total_score := NULL) AS vars
    WHERE TotalPosts > 0
    ORDER BY TotalScore DESC
),
PostScoreHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        P.Score,
        (SELECT 
             COUNT(*) 
         FROM Votes V 
         WHERE V.PostId = P.Id 
         AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT 
             COUNT(*) 
         FROM Votes V 
         WHERE V.PostId = P.Id 
         AND V.VoteTypeId = 3) AS DownvoteCount
    FROM Posts P
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),
PostRecentActivity AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH
    AND PH.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    TU.DisplayName,
    TU.Upvotes,
    TU.Downvotes,
    TU.TotalPosts,
    TU.TotalScore,
    PS.PostId,
    PS.Title,
    PS.LastActivityDate,
    PS.Score,
    PS.UpvoteCount,
    PS.DownvoteCount,
    COUNT(PRA.UserId) AS RecentActivityCount
FROM TopUsers TU
JOIN PostScoreHistory PS ON TU.UserId = PS.PostId
LEFT JOIN PostRecentActivity PRA ON PS.PostId = PRA.PostId
GROUP BY 
    TU.DisplayName, 
    TU.Upvotes, 
    TU.Downvotes, 
    TU.TotalPosts, 
    TU.TotalScore, 
    PS.PostId, 
    PS.Title, 
    PS.LastActivityDate, 
    PS.Score, 
    PS.UpvoteCount, 
    PS.DownvoteCount
ORDER BY TU.TotalScore DESC, PS.Score DESC
LIMIT 100;
