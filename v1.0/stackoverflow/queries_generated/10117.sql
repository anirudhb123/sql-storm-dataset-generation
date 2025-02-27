-- Performance benchmarking for various queries in the Stack Overflow schema

-- 1. Count the number of posts by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- 2. Average reputation of users who have posted questions
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1; -- Only questions

-- 3. Total views of all posts by tag
SELECT 
    t.TagName,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
GROUP BY 
    t.TagName
ORDER BY 
    TotalViews DESC;

-- 4. Most commented posts and their comment count
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;

-- 5. Top users by number of answers posted
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 2 -- Only answers
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    AnswerCount DESC
LIMIT 10;

-- 6. Most recent edits to posts
SELECT 
    p.Title,
    ph.CreationDate,
    ph.UserDisplayName,
    ph.Comment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;

-- 7. Distribution of votes by type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;
