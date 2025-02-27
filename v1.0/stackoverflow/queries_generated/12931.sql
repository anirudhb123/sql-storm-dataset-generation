-- Performance Benchmarking Query

-- Retrieve the count of posts, including post types and the associated user reputation
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Get the average view count and score of questions categorized by tags
SELECT 
    t.TagName,
    COUNT(p.Id) AS QuestionCount,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    p.PostTypeId = 1  -- Only consider questions
GROUP BY 
    t.TagName
ORDER BY 
    QuestionCount DESC;

-- Evaluate the distribution of votes across posts and the average score of these posts
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS VoteCount,
    AVG(p.Score) AS AveragePostScore
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
JOIN 
    Posts p ON v.PostId = p.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- Assess the number of comments and average score per post type
SELECT 
    pt.Name AS PostTypeName,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) AS AveragePostScore
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    CommentCount DESC;
