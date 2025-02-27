
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 9 
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.Reputation
), 
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C) AS CommentCount,
        MAX(P.LastActivityDate) AS LastActivity,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY P.Id, P.OwnerUserId
), 
RankedPosts AS (
    SELECT 
        R.OwnerUserId,
        R.PostId,
        R.CommentCount,
        R.LastActivity,
        R.CloseCount,
        @row_number := IF(@current_owner_user_id = R.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_owner_user_id := R.OwnerUserId
    FROM RecentPostActivity R
    CROSS JOIN (SELECT @row_number := 0, @current_owner_user_id := NULL) AS vars
    ORDER BY R.OwnerUserId, R.CommentCount DESC, R.LastActivity DESC
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.TotalBounties,
    RP.PostId,
    RP.CommentCount,
    RP.LastActivity,
    RP.CloseCount
FROM Users U
JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN RankedPosts RP ON U.Id = RP.OwnerUserId
WHERE RP.Rank <= 5 OR RP.Rank IS NULL
ORDER BY UR.Reputation DESC, RP.CommentCount DESC;
