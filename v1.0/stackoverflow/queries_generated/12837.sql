-- Performance benchmarking query for Stack Overflow schema

-- This query benchmarks the number of posts, average score, and user reputation to gauge post interaction quality
SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(u.Reputation) AS TotalUserReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Considering posts created in the last year
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;

-- Performance benchmarking query to analyze user engagement through comments
SELECT 
    p.Id AS PostId,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore,
    MAX(c.CreationDate) AS LatestCommentDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '6 months'  -- Considering posts from the last 6 months
GROUP BY 
    p.Id
ORDER BY 
    CommentCount DESC;

-- Performance benchmarking query to assess the usage of tags and their engagement
SELECT 
    t.TagName,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.AnswerCount) AS AverageAnswers
FROM 
    Tags t
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Considering the last year
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC;
