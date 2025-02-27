WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        AVG(V.BountyAmount) AS AverageBounty,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.Score > 0
    GROUP BY 
        P.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
        AND PH.CreationDate >= NOW() - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.AverageBounty,
        COALESCE(CP.ClosedDate, 'No Closure') AS ClosedDate,
        COALESCE(CP.CloseReason, 'N/A') AS CloseReason
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
    WHERE 
        RP.PostRank <= 5 -- Top 5 posts per user based on creation date
)
SELECT 
    PM.Title,
    PM.OwnerDisplayName,
    PM.CommentCount,
    PM.AverageBounty,
    PM.ClosedDate,
    PM.CloseReason,
    (CASE 
        WHEN PM.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
     END) AS PostStatus
FROM 
    PostMetrics PM
ORDER BY 
    PM.CommentCount DESC, PM.AverageBounty DESC;
