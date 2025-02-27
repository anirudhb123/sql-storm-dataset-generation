
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        @row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS RN,
        @prev_owner_user_id := P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        U.DisplayName AS OwnerDisplayName,
        UVC.TotalVotes,
        UVC.UpVotes,
        UVC.DownVotes,
        RP.CommentCount,
        COALESCE((SELECT COUNT(1) FROM PostLinks PL WHERE PL.PostId = RP.PostId), 0) AS RelatedPostCount
    FROM RecentPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN UserVoteCounts UVC ON U.Id = UVC.UserId
    WHERE RP.RN = 1
)
SELECT 
    PS.Title,
    PS.OwnerDisplayName,
    PS.TotalVotes,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.RelatedPostCount,
    CASE 
        WHEN PS.TotalVotes > 0 THEN (CAST(PS.UpVotes AS DECIMAL(10,2)) / PS.TotalVotes) * 100
        ELSE 0 
    END AS UpVotePercentage
FROM PostStatistics PS
WHERE PS.CommentCount > 5
ORDER BY UpVotePercentage DESC
LIMIT 10;
