
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        STUFF((SELECT DISTINCT ', ' + pt.Name 
               FROM PostTypes pt 
               WHERE pt.Id = p.PostTypeId 
               FOR XML PATH('')), 1, 2, '') AS PostTypeNames
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),

TopPosts AS (
    SELECT 
        PostID,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        PostTypeNames
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3  
)

SELECT 
    up.DisplayName,
    COUNT(DISTINCT tp.PostID) AS TotalPosts,
    SUM(tp.ViewCount) AS TotalViews,
    AVG(tp.Score) AS AverageScore,
    STUFF((
        SELECT DISTINCT ', ' + tp2.PostTypeNames 
        FROM TopPosts tp2 
        WHERE tp2.PostID = tp.PostID 
        FOR XML PATH('')), 1, 2, '') AS PostTypes,
    STUFF((
        SELECT DISTINCT ', ' + tp2.Tags 
        FROM TopPosts tp2 
        WHERE tp2.PostID = tp.PostID 
        FOR XML PATH('')), 1, 2, '') AS AllTags
FROM 
    TopPosts tp
JOIN 
    Users up ON tp.PostID IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = up.Id)
GROUP BY 
    up.Id, up.DisplayName
ORDER BY 
    TotalPosts DESC, TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
