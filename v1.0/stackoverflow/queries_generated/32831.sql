WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        CAST(p.Title AS VARCHAR(300)) AS FullTitle,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Starting point for top-level posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        CAST(CONCAT(ph.FullTitle, ' > ', p.Title) AS VARCHAR(300)) AS FullTitle,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ph.FullTitle,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(ph.Level) AS MaxLevel
FROM 
    PostHierarchy ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tagName ON TRUE
LEFT JOIN 
    Tags t ON TRIM(BOTH ' ' FROM tagName) = t.TagName
GROUP BY 
    u.DisplayName, u.Reputation, ph.FullTitle, p.CreationDate
HAVING 
    COUNT(c.Id) > 0 -- Ensure there are comments on the posts
ORDER BY 
    u.Reputation DESC,
    MaxLevel DESC;

This query performs a recursive Common Table Expression (CTE) to build a hierarchy of posts, allowing for the aggregation of data related to the root posts and their child posts. It retrieves user information, post details, comment counts, and vote counts along with related tags, filtering for posts that have received comments, and orders the results by user reputation and post hierarchy level.
