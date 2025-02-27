-- Performance benchmarking query for Stack Overflow schema

-- Query to retrieve the count of posts by type and their average score and view count
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Query to analyze user engagement by counting the number of votes and comments made by each user
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalVotes DESC, TotalComments DESC;

-- Query to analyze badges awarded based on user reputation
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    BadgeCount DESC;

-- Query to measure the frequency of posts being edited by the type of edit
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS EditCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    EditCount DESC;

-- Query to get the distribution of tags used in posts
SELECT 
    t.TagName,
    COUNT(pt.Id) AS PostCount
FROM 
    Tags t
LEFT JOIN 
    Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
GROUP BY 
    t.TagName
ORDER BY 
    PostCount DESC;
