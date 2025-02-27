WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PostHistories AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12)  -- Close, Reopen, Delete
    GROUP BY 
        PH.PostId, 
        PH.PostHistoryTypeId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName AS Owner,
    U.Reputation,
    U.BadgeCount,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    PH.ChangeCount,
    PH.LastChangeDate,
    COALESCE(NULLIF(PH.ChangeCount, 0), 1) AS NonZeroChangeCount, 
    CASE 
        WHEN RP.Score > 100 THEN 'Hot Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    RecentPosts RP
LEFT JOIN 
    UserReputation U ON RP.OwnerUserId = U.UserId
LEFT JOIN 
    PostHistories PH ON RP.PostId = PH.PostId
WHERE 
    RP.PostRank <= 5  -- Focus on the top 5 recent posts per user
ORDER BY 
    RP.CreationDate DESC
LIMIT 100;

-- Additional unusual corner cases and NULL logic
SELECT 
    *,
    (CASE 
        WHEN U.Reputation IS NULL THEN 'Reputation info not available' 
        ELSE 'User has reputation'
    END) AS ReputationStatus,
    (CASE 
        WHEN RP.CommentCount > 0 THEN 'Has comments' 
        ELSE 'No comments made'
    END) AS CommentStatus
FROM 
    (SELECT 
        RP.*, 
        U.DisplayName 
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id
    ) AS SubQuery 
WHERE 
    SubQuery.Title IS NOT NULL
    OR SubQuery.CommentCount IS NULL;
