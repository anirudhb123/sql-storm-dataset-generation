WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from root questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
    AVG(v.CreationDate - p.CreationDate) AS AvgVoteDelay,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed,
    MAX(p.Score) AS MaxPostScore,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    COUNT(DISTINCT ph.PostId) AS RelatedPostsCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- Using string matching for tags
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
WHERE 
    u.Reputation > 1000 
    AND (p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' OR p.Id IS NULL) -- Recent posts or no posts 
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 posts
ORDER BY 
    TotalPosts DESC
LIMIT 10;

This SQL query provides a comprehensive analysis of users along with their contributions in terms of posts, tags, and badges earned while implementing several advanced SQL constructs such as recursive CTEs, joins, aggregates, and string matching.
