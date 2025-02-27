-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the number of posts, users, votes, and comments, grouped by post type,
-- as well as average scores and view counts, to assess the performance of different post types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    COUNT(DISTINCT u.Id) AS UserCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
