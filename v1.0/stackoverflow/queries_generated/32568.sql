WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > UR.Reputation
    WHERE UR.Level < 5 -- Limit to 5 levels of reputation hierarchy
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        COALESCE(P.Score, 0) AS Score,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Filter for recent posts
    GROUP BY P.Id
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.CreationDate,
        PD.Score,
        PD.OwnerUserId,
        PD.CommentCount,
        RANK() OVER (PARTITION BY PD.OwnerUserId ORDER BY PD.Score DESC, PD.ViewCount DESC) AS PostRank
    FROM PostDetails PD
    WHERE PD.CommentCount > 0
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    RP.PostRank
FROM Users U
JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN RankedPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE U.Reputation IS NOT NULL
ORDER BY UR.Reputation DESC, RP.Score DESC, RP.ViewCount DESC;
