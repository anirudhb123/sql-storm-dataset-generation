-- Performance Benchmarking Query

-- Aggregate User Statistics
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, Reputation DESC;

-- Analyzing Post Types and Activity
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgPostScore,
    AVG(p.ViewCount) AS AvgViewCount,
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

-- Recent Post Edits History
SELECT 
    ph.CreationDate,
    p.Title,
    p.OwnerDisplayName,
    p.LastEditorDisplayName,
    p.LastEditDate,
    p.Tags,
    p.ViewCount,
    ph.Comment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, or Tags
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;

-- Most Active Posts by Comment Count
SELECT 
    p.Title,
    p.ViewCount,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, p.ViewCount
ORDER BY 
    TotalComments DESC
LIMIT 50;

-- Popular Tags and associated Posts
SELECT 
    t.TagName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Tags t
LEFT JOIN 
    Posts p ON t.Id = ANY(string_to_array(p.Tags, '::text')::int[])
GROUP BY 
    t.TagName
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 50;
