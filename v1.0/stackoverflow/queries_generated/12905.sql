-- Performance Benchmarking Query

-- This query retrieves the number of posts, total view count, and average score of questions, grouped by the user's reputation level.
SELECT 
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViewCount,
    AVG(p.Score) AS AverageScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 -- Only considering questions
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;

-- This query analyzes the distribution of post types with the count of posts and comments for each type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    COUNT(c.Id) AS CommentCount
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query retrieves the most recent edits and their types for each post to evaluate editing activity.
SELECT 
    p.Title,
    ph.CreationDate AS EditDate,
    pht.Name AS EditType,
    ph.UserDisplayName AS EditedBy
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate > CURRENT_DATE - INTERVAL '30 days'  -- Edits within the last 30 days
ORDER BY 
    ph.CreationDate DESC;

-- This query benchmarks the changes in votes over time for a specific post.
SELECT 
    v.CreationDate AS VoteDate,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    v.PostId = :PostId  -- Replace with the specific PostId you want to analyze
GROUP BY 
    v.CreationDate, vt.Name
ORDER BY 
    VoteDate DESC;
