-- Performance Benchmarking Query for StackOverflow Schema

-- 1. Count the number of posts, group by PostType and include average score
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. User statistics: Count of posts and average reputation per user
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- 3. Count of comments per post with average score
SELECT 
    p.Title,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalComments DESC;

-- 4. Badges awarded statistics
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalAwards
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    TotalAwards DESC;

-- 5. Active posts: Posts created in the last year
SELECT 
    COUNT(Id) AS ActivePostsLastYear
FROM 
    Posts
WHERE 
    CreationDate >= DATEADD(year, -1, GETDATE());

-- 6. Closing reasons statistics from PostHistory
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS CloseReasonCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes cht ON ph.PostHistoryTypeId = cht.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Interested in post closure and reopening reasons
GROUP BY 
    cht.Name
ORDER BY 
    CloseReasonCount DESC;

-- 7. Top users by votes received
SELECT 
    u.DisplayName,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,
    SUM(v.VoteTypeId = 3) AS TotalDownvotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalUpvotes DESC;
