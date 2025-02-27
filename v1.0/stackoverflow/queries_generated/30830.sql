WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
)
SELECT 
    u.DisplayName AS Author,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(COALESCE(ph.ViewCount, 0)) AS TotalViews,
    MAX(ph.CreationDate) AS LastPosted,
    AVG(ph.Score) AS AvgScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    (SELECT COUNT(*) 
     FROM Comments c
     WHERE c.PostId = p.Id) AS CommentCount,
     CASE 
       WHEN MAX(ph.CreationDate) < NOW() - INTERVAL '1 year' THEN 'Inactive'
       ELSE 'Active'
    END AS ActivityStatus
FROM 
    Users u
JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    RecursivePostCTE r ON r.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2 -- Upvotes
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '5 years'
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- Users with more than 10 questions
ORDER BY 
    TotalViews DESC;


