WITH RecursiveTagHierarchy AS (
    -- Step 1: Get the initial set of tags 
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        1 AS Level
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0  -- Only consider public (non-moderator-only) tags

    UNION ALL

    -- Step 2: Recursively find related tags by joining Posts
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        r.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    INNER JOIN 
        RecursiveTagHierarchy r ON r.TagId = p.Id
)

-- Main query: Performance benchmarking of posts and their related tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(b.Name) AS BadgeName,
    MAX(b.Class) AS BadgeClass,
    MAX(u.Reputation) AS AuthorReputation,
    RANK() OVER (PARTITION BY r.Level ORDER BY p.Score DESC) AS PostRanking
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RecursiveTagHierarchy r ON TRUE  -- Join recursively to get all levels of tags
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter posts created within last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
HAVING 
    COUNT(DISTINCT c.Id) > 0  -- Only include posts with comments
ORDER BY 
    PostRanking, p.CreationDate DESC;  -- Order by post ranking and then creation date
