WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select questions as root posts
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    u.DisplayName AS Author,
    MAX(ph.CreationDate) AS LastActivityDate,
    COUNT(reply.Id) AS ReplyCount,
    SUM(vt.VoteTypeId = 2) AS UpvoteCount,
    SUM(vt.VoteTypeId = 3) AS DownvoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY MAX(ph.CreationDate) DESC) as Rank
FROM 
    PostHierarchy ph
JOIN 
    Posts reply ON reply.ParentId = ph.PostId
JOIN 
    Users u ON reply.OwnerUserId = u.Id
LEFT JOIN 
    Votes vt ON vt.PostId = reply.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(ph.Tags, ',')) AS TagName
    ) t ON true
WHERE 
    ph.CreationDate > NOW() - INTERVAL '1 month' -- Focus on posts in the last month
GROUP BY 
    u.Id
HAVING 
    COUNT(reply.Id) > 2 -- Only users with more than 2 replies
ORDER BY 
    LastActivityDate DESC;

-- Additional performance testing constructs:

-- Collect performance metrics based on execution plan and row counts
EXPLAIN ANALYZE 
SELECT 
    *
FROM 
    Users 
WHERE 
    Reputation > (
        SELECT AVG(Reputation) FROM Users WHERE LastAccessDate < NOW() - INTERVAL '1 year'
    )
AND 
    EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = Users.Id AND b.Class = 1 
    )
OR 
    (WebsiteUrl IS NOT NULL AND Location IS NOT NULL);
