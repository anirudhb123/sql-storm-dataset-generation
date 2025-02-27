
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
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        (SELECT TagName FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName 
        FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
              SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION 
              SELECT 9 UNION SELECT 10) n) AS t) AS t ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' AND
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
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
    GROUP_CONCAT(DISTINCT t.Title SEPARATOR '; ') AS TopPostTitles,
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
