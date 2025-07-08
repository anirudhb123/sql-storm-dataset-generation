
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
        ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score
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
    LISTAGG(DISTINCT tp.PostTypeNames::text, ', ') WITHIN GROUP (ORDER BY tp.PostTypeNames) AS PostTypes,
    LISTAGG(DISTINCT tp.Tags, ', ') WITHIN GROUP (ORDER BY tp.Tags) AS AllTags
FROM 
    TopPosts tp
JOIN 
    Users up ON tp.PostID IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = up.Id)
GROUP BY 
    up.Id, up.DisplayName
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 10;
