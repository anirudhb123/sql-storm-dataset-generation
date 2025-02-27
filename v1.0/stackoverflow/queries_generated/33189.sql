WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS Author,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    RANK() OVER (ORDER BY r.Score DESC) AS Rank
FROM 
    RecursiveCTE r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON r.PostId = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN p.Tags) > 0 
WHERE 
    r.Level <= 3 
GROUP BY 
    u.DisplayName, r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount
HAVING 
    COUNT(c.Id) > 0 AND COUNT(DISTINCT b.Id) >= 2 -- Only include posts with comments and at least 2 badges
ORDER BY 
    TotalBounty DESC, Rank ASC;

This SQL query performs a series of complex operations:

1. It uses a recursive CTE to gather questions and their answers, limiting the depth to three levels.
2. The main SELECT statement aggregates data, combining user information, bounty totals, comment counts, badge counts, and associated tags.
3. It applies window functions to rank the results based on post score.
4. It includes various types of joins (INNER, LEFT) to fetch the required data from multiple tables, along with null handling through COALESCE.
5. Finally, it filters results using HAVING to ensure only posts with comments and specific badge conditions are returned.
