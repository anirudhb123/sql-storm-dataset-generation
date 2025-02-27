
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
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '>')) AS t
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') AND
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
    STRING_AGG(DISTINCT t.Title, '; ') AS TopPostTitles,
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
