WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS LatestHistory
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.LatestHistory = 1
      AND 
        rp.Score > 10
)
SELECT 
    fp.Title,
    fp.Author,
    fp.CreationDate,
    fp.Score,
    ROUND(AVG(fp.ViewCount), 2) AS AverageViewCount,
    SUM(fp.CommentCount) AS TotalComments
FROM 
    FilteredPosts fp
JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(fp.Title, 2, length(fp.Title) - 2), '>')::int[])  -- Assume tags are represented in Title
WHERE 
    t.IsModeratorOnly = 0
GROUP BY 
    fp.Title, fp.Author, fp.CreationDate, fp.Score
ORDER BY 
    TotalComments DESC, AverageViewCount DESC
LIMIT 100 OFFSET 0;
