
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(p.Tags, '>') AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate >= TO_TIMESTAMP('2024-10-01 12:34:56') - INTERVAL '1 year' AND
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    t.OwnerDisplayName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(p.Score) AS AverageScore,
    LISTAGG(DISTINCT t.Title, '; ') WITHIN GROUP (ORDER BY t.Title) AS TopPostTitles,
    SUM(p.ViewCount) AS TotalViews
FROM 
    TopPosts t
JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
JOIN 
    Posts p ON p.OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    AverageScore DESC, TotalViews DESC;
