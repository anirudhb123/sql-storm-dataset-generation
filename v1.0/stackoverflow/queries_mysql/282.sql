
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes_Count,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes_Count,
        COUNT(DISTINCT P.Id) AS Posts_Count,
        COUNT(DISTINCT C.Id) AS Comments_Count
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        PH.PostHistoryTypeId,
        @row_num := IF(@prev_post_id = PH.PostId, @row_num + 1, 1) AS RecentHistory,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    CROSS JOIN (SELECT @row_num := 0, @prev_post_id := NULL) AS vars
    WHERE 
        PH.PostHistoryTypeId IN (10, 12, 11) 
    ORDER BY 
        PH.PostId, PH.CreationDate DESC
),
RankingUsers AS (
    SELECT 
        UserId,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        UserStatistics, (SELECT @user_rank := 0) AS vars
    ORDER BY 
        Reputation DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes_Count,
    U.DownVotes_Count,
    U.Posts_Count,
    U.Comments_Count,
    PH.Comment AS PostHistoryComment,
    P.Title AS PostTitle,
    PH.CreationDate AS HistoryDate,
    R.UserRank
FROM 
    UserStatistics U
LEFT JOIN 
    PostHistoryDetails PH ON U.UserId = PH.UserId
JOIN 
    Posts P ON PH.PostId = P.Id
JOIN 
    RankingUsers R ON U.UserId = R.UserId
WHERE 
    U.Reputation > 1000
    AND PH.RecentHistory = 1
ORDER BY 
    U.Reputation DESC, 
    PH.CreationDate DESC;
