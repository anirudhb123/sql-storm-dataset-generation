-- Performance Benchmarking Query

-- This query will provide insights into the statistics of posts, including the number of questions, answers, upvotes, etc.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
    SUM(CASE WHEN p.AwardedDate IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
    AVG(COALESCE(DATEDIFF(MINUTE, p.CreationDate, p.LastActivityDate), 0)) AS AvgActiveTimeMinutes,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END, 0)) AS TotalAnswersToQuestions
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query will benchmark the performance of Users and their contributions based on Badge achievement.
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(p.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(p.DownVotes, 0)) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    BadgeCount DESC;

-- This query will evaluate the activity within the Comments, summarizing comment counts by post.
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    SUM(COALESCE(V.CoteId, 0)) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes V ON c.PostId = V.PostId
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC;

-- This query benchmarks performance on PostHistory showing types and historical edits.
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastModified
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;
