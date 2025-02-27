WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerUserId,
        0 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy cte ON p.ParentId = cte.Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        R.Id AS PostId,
        R.Title,
        R.CreationDate,
        R.Score,
        R.ViewCount,
        COALESCE(U.DisplayName, 'Deleted User') AS OwnerDisplayName,
        PT.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY R.OwnerUserId ORDER BY R.Score DESC) AS Rank
    FROM 
        RecursivePostHierarchy R
    LEFT JOIN 
        Users U ON R.OwnerUserId = U.Id
    LEFT JOIN 
        PostTypes PT ON R.PostTypeId = PT.Id
)
SELECT 
    UStats.UserId,
    UStats.DisplayName,
    UStats.TotalScore,
    UStats.PostCount,
    UStats.CommentCount,
    UStats.BadgeCount,
    TPosts.PostId,
    TPosts.Title AS TopPostTitle,
    TPosts.CreationDate AS TopPostDate,
    TPosts.Score AS TopPostScore,
    TPosts.ViewCount AS TopPostViews
FROM 
    UserStatistics UStats
LEFT JOIN 
    TopPosts TPosts ON UStats.UserId = TPosts.OwnerUserId AND TPosts.Rank = 1
WHERE 
    UStats.TotalScore > 1000
ORDER BY 
    UStats.TotalScore DESC,
    UStats.DisplayName ASC
OPTION (RECOMPILE);
