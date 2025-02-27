WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        CAST(P.Title AS VARCHAR(MAX)) AS HierarchicalPath,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        CAST(RPH.HierarchicalPath + ' -> ' + P.Title AS VARCHAR(MAX)),
        RPH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        Level,
        HierarchicalPath,
        ROW_NUMBER() OVER (PARTITION BY Level ORDER BY ViewCount DESC) AS RowNum
    FROM 
        RecursivePostHierarchy
    WHERE 
        Level <= 3 -- Limit to a hierarchy of 3
),
PostAggregate AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.ViewCount,
        FP.Score,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(C.Id) AS CommentCount,
        CASE 
            WHEN FP.Score > 10 THEN 'High Score'
            WHEN FP.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        FilteredPosts FP
    LEFT JOIN 
        Votes V ON V.PostId = FP.PostId AND V.VoteTypeId = 9 -- Only consider BountyClose votes
    LEFT JOIN 
        Comments C ON C.PostId = FP.PostId
    GROUP BY 
        FP.PostId, FP.Title, FP.ViewCount, FP.Score
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PHT.Name AS ChangeType,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PHT.Name
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.ViewCount,
    PA.Score,
    PA.TotalBounty,
    PA.CommentCount,
    PA.ScoreCategory,
    COALESCE(PHI.ChangeCount, 0) AS HistoryChangeCount,
    PHI.ChangeType
FROM 
    PostAggregate PA
LEFT JOIN 
    PostHistoryInfo PHI ON PA.PostId = PHI.PostId
ORDER BY 
    PA.ViewCount DESC,
    PA.Score DESC;
