
WITH RankedPosts AS (
    SELECT 
        Id AS PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate,
        @row_number := IF(@prev_post_type = PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := PostTypeId
    FROM Posts, (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE CreationDate >= CURDATE() - INTERVAL 1 YEAR
    ORDER BY PostTypeId, Score DESC, ViewCount DESC
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived,
        SUM(CASE WHEN U.Location IS NOT NULL THEN 1 ELSE 0 END) AS UsersWithLocation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId, 
        P.Title,
        PH.Comment,
        PH.CreationDate AS HistoryDate,
        (SELECT GROUP_CONCAT(NAME SEPARATOR ', ') 
         FROM PostHistoryTypes PHT 
         WHERE PHT.Id = PH.PostHistoryTypeId) AS HistoryType
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= CURDATE() - INTERVAL 6 MONTH
),
HighScoringPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount
    FROM RankedPosts RP
    WHERE RP.Rank <= 10
),
FinalResults AS (
    SELECT 
        U.DisplayName,
        U.TotalPosts,
        U.UpvotesReceived,
        U.DownvotesReceived,
        COALESCE(HP.Score, 0) AS TopPostScore,
        COALESCE(HP.ViewCount, 0) AS TopPostViews,
        PHD.HistoryType,
        PHD.Comment
    FROM UserActivity U
    LEFT JOIN HighScoringPosts HP ON U.TotalPosts > 0 
        OR (U.UpvotesReceived - U.DownvotesReceived) > 10
    LEFT JOIN PostHistoryDetails PHD ON HP.PostId = PHD.PostId
)

SELECT 
    DisplayName,
    TotalPosts,
    UpvotesReceived,
    DownvotesReceived,
    TopPostScore,
    TopPostViews,
    HistoryType,
    Comment
FROM FinalResults
WHERE (DownvotesReceived IS NULL OR DownvotesReceived < UpvotesReceived)
ORDER BY UpvotesReceived DESC, TotalPosts DESC
LIMIT 10 OFFSET 5;
