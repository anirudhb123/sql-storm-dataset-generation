
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        @row_number := @row_number + 1 AS ReputationRank
    FROM
        Users U, (SELECT @row_number := 0) AS init
    ORDER BY U.Reputation DESC
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        @rank := IF(@prev_owner_user_id = P.OwnerUserId, @rank + 1, 1) AS RecentPostRank,
        @prev_owner_user_id := P.OwnerUserId
    FROM
        Posts P 
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    JOIN (SELECT @rank := 0, @prev_owner_user_id := NULL) AS init ON true
    WHERE
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > (SELECT AVG(Reputation) FROM Users)
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        P.Title,
        PH.Comment,
        @close_history_rank := IF(@prev_post_id = PH.PostId, @close_history_rank + 1, 1) AS CloseHistoryRank,
        @prev_post_id := PH.PostId
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN (SELECT @close_history_rank := 0, @prev_post_id := NULL) AS init ON true
    WHERE 
        PH.PostHistoryTypeId = 10 
)

SELECT
    UR.DisplayName,
    UR.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CommentCount,
    CP.ClosedDate,
    CP.Comment AS CloseReasonComment
FROM
    TopUsers UR
LEFT JOIN
    RecentPosts RP ON UR.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN
    ClosedPosts CP ON RP.PostId = CP.PostId AND CP.CloseHistoryRank = 1
WHERE
    UR.Reputation > 1000
ORDER BY 
    UR.Reputation DESC
LIMIT 10;
