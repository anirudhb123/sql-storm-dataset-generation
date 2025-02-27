WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
),
UserSummary AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        TP.Title,
        TP.PostId,
        TP.ViewCount,
        TP.Score,
        TP.CommentCount,
        CP.CloseReason
    FROM 
        UserReputation UR
    LEFT JOIN 
        TopPosts TP ON UR.UserId = TP.OwnerUserId
    LEFT JOIN 
        ClosedPosts CP ON TP.PostId = CP.PostId
)
SELECT 
    Us.DisplayName,
    Us.Reputation,
    Us.Title,
    Us.ViewCount,
    Us.Score,
    Us.CommentCount,
    Us.CloseReason,
    CASE 
        WHEN Us.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    UserSummary Us
WHERE 
    Us.Reputation > 1000
ORDER BY 
    Us.Reputation DESC,
    Us.Score DESC;
