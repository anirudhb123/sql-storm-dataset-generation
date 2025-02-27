WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000  -- Start with users who have a significant reputation

    UNION ALL

    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > (UR.Reputation / 2)  -- Recursive condition based on reputation
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- Bounty start and close
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on recent posts
    GROUP BY P.Id, P.OwnerUserId
),

UserPostDetails AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        PS.PostId,
        PS.TotalBounty,
        PS.CommentCount,
        PS.RelatedPostCount,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.TotalBounty DESC) AS Rank
    FROM Users U
    JOIN PostStats PS ON U.Id = PS.OwnerUserId
    JOIN UserReputation UR ON U.Id = UR.UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    CASE 
        WHEN UPD.CommentCount > 5 THEN 'High Engagement'
        WHEN UPD.CommentCount BETWEEN 3 AND 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    UPD.TotalBounty,
    UPD.RelatedPostCount,
    UPD.Rank
FROM UserPostDetails UPD
JOIN Users U ON UPD.PostId = U.Id
WHERE UPD.Rank = 1  -- Select highest reputation for each user
AND U.Reputation IS NOT NULL
ORDER BY U.Reputation DESC, UPD.TotalBounty DESC;
