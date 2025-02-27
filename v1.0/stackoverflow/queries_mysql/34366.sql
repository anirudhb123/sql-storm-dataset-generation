
WITH RECURSIVE ActiveUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        CreationDate,
        LastAccessDate,
        @rownum := @rownum + 1 AS UserRank
    FROM Users, (SELECT @rownum := 0) r
    WHERE Reputation > 1000
    ORDER BY Reputation DESC
),
PostsWithScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.Score, 0) AS PostScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY P.Id, P.Title, P.Score, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PWS.PostId,
        PWS.Title,
        PWS.PostScore,
        PWS.CommentCount,
        PWS.TotalBounty,
        AU.DisplayName AS OwnerName,
        AU.Reputation AS OwnerReputation,
        @rank := IF(@prev_post_score = (PWS.PostScore + PWS.TotalBounty), @rank, @rank + 1) AS Rank,
        @prev_post_score := (PWS.PostScore + PWS.TotalBounty)
    FROM PostsWithScores PWS, (SELECT @rank := 0, @prev_post_score := NULL) r
    JOIN ActiveUsers AU ON PWS.OwnerUserId = AU.Id
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason,
        P.Title,
        @recentCloseRank := IF(@prev_post_id = P.Id, @recentCloseRank + 1, 1) AS RecentClose,
        @prev_post_id := P.Id
    FROM Posts P, (SELECT @recentCloseRank := 0, @prev_post_id := NULL) r
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 
)
SELECT 
    TP.Title,
    TP.PostScore,
    TP.CommentCount,
    TP.TotalBounty,
    TP.OwnerName,
    TP.OwnerReputation,
    COALESCE(CP.CloseReason, 'Not Closed') AS LastCloseReason
FROM TopPosts TP
LEFT JOIN ClosedPosts CP ON TP.PostId = CP.PostId AND CP.RecentClose = 1
WHERE TP.Rank <= 10 
ORDER BY TP.PostScore DESC;
