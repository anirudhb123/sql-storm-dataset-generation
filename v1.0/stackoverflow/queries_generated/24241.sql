WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Owner,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RankByCreation
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) -- Considering only Questions and Answers
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        PH.CreationDate AS CloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
        AND PH.CreationDate >= NOW() - INTERVAL '6 months'
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.Owner,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        COUNT(CM.Id) AS CommentCount,
        AVG(COALESCE(VB.BountyAmount, 0)) AS AverageBounty
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
    LEFT JOIN 
        Comments CM ON RP.PostId = CM.PostId
    LEFT JOIN 
        Votes VB ON RP.PostId = VB.PostId AND VB.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.ViewCount, RP.Owner, CP.CloseReason
),
FinalReport AS (
    SELECT 
        PS.*,
        CASE 
            WHEN PS.Score >= 10 THEN 'High Score'
            WHEN PS.Score BETWEEN 5 AND 9 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        CASE 
            WHEN PS.ViewCount IS NULL OR PS.ViewCount = 0 THEN 'No Views Yet'
            WHEN PS.ViewCount < 100 THEN 'Low Visibility'
            ELSE 'High Visibility'
        END AS VisibilityStatus
    FROM 
        PostStatistics PS
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.Score,
    FR.ViewCount,
    FR.Owner,
    FR.CloseReason,
    FR.CommentCount,
    FR.AverageBounty,
    FR.ScoreCategory,
    FR.VisibilityStatus
FROM 
    FinalReport FR
WHERE 
    FR.RankByCreation <= 5 -- Get top 5 recent posts per PostType
ORDER BY 
    FR.Score DESC, 
    FR.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination for the result
