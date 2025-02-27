WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score >= 10
        AND P.CreationDate >= NOW() - INTERVAL '30 days'
),
UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        CASE 
            WHEN U.Reputation IS NULL THEN 'N/A'
            WHEN U.Reputation < 50 THEN 'Newbie'
            WHEN U.Reputation BETWEEN 50 AND 200 THEN 'Intermediate'
            ELSE 'Expert' 
        END AS ReputationTier
    FROM 
        Users U
),
FilteredComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        PH.CreationDate AS ClosureDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- closed or reopened
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    UR.DisplayName,
    UR.ReputationTier,
    COALESCE(FC.CommentCount, 0) AS TotalComments,
    COALESCE(FC.LastCommentDate, 'No comments') AS LastComment,
    CP.CloseReason,
    CP.ClosureDate
FROM 
    RankedPosts RP
LEFT JOIN 
    UserReputations UR ON RP.OwnerUserId = UR.UserId
LEFT JOIN 
    FilteredComments FC ON RP.PostId = FC.PostId
LEFT JOIN 
    ClosedPostDetails CP ON RP.PostId = CP.PostId
WHERE 
    (CP.CloseReason IS NULL OR RP.Score > 15) -- Only include posts with a score > 15 if closed
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC
LIMIT 50;

-- Using UNION to find distinct post owners and their total upvotes in combination with user reputation
UNION

SELECT 
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    U.DisplayName,
    CASE 
        WHEN U.Reputation IS NULL THEN 'N/A'
        ELSE 'Other'
    END AS ReputationTier,
    SUM(V.VoteTypeId = 2) AS UpVoteCount,
    NULL AS LastComment,
    NULL AS CloseReason,
    NULL AS ClosureDate
FROM 
    Users U
JOIN 
    Votes V ON U.Id = V.UserId
WHERE 
    U.Reputation >= 50
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(V.Id) >= 5
ORDER BY 
    UpVoteCount DESC
LIMIT 50;
