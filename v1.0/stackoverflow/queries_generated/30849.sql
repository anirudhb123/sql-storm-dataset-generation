WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.OwnerUserId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        Posts pp ON pp.AcceptedAnswerId = p2.Id
    WHERE 
        pp.PostTypeId = 1
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    u.DisplayName AS OwnerName,
    COUNT(a.Id) AS AnswerCount,
    COALESCE(MAX(b.Reputation), 0) AS HighestReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    Users u ON ph.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = ph.PostId AND a.PostTypeId = 2
LEFT JOIN 
    Comments c ON c.PostId = ph.PostId
LEFT JOIN 
    Tags t ON ', ' || ph.Title || ', ' LIKE '%,' || t.TagName || ',%'
LEFT JOIN 
    Votes v ON v.PostId = ph.PostId
LEFT JOIN 
    Badges b ON b.UserId = ph.OwnerUserId
GROUP BY 
    ph.PostId, ph.Title, u.DisplayName, ph.CreationDate
HAVING 
    COUNT(a.Id) > 5 AND MAX(b.Reputation) IS NOT NULL
ORDER BY 
    CreationDate DESC
LIMIT 100;
