-- Performance benchmarking query for the Stack Overflow schema

-- Retrieve user information along with post statistics
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
    COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    AVG(COALESCE(p.ViewCount, 0)) AS AverageViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;

-- Performance testing of posts with their associated tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    ARRAY_AGG(t.TagName) AS Tags,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount
FROM 
    Posts p
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '>')) AS tag_id ON tag_id IS NOT NULL
LEFT JOIN 
    Tags t ON t.Id = tag_id::int
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

-- Benchmarking the comments made on posts
SELECT 
    c.Id AS CommentId,
    c.PostId,
    c.Text,
    c.CreationDate,
    u.DisplayName AS CommenterName,
    COUNT(*) OVER (PARTITION BY c.PostId) AS TotalComments
FROM 
    Comments c
JOIN 
    Users u ON c.UserId = u.Id
ORDER BY 
    c.CreationDate DESC
LIMIT 100;
