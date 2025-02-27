-- Performance Benchmarking Query: Analyze the distribution of posts by type and their engagement metrics (scores, views, answer count)
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments,
    SUM(p.FavoriteCount) AS TotalFavorites
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance Benchmarking Query: Access frequency of posts based on upvotes and downvotes
SELECT 
    p.Title,
    p.CreationDate,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month' -- Consider posts created in the last month
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    VoteCount DESC;

-- Performance Benchmarking Query: Average reputation of users who created questions
SELECT 
    AVG(u.Reputation) AS AverageReputation,
    COUNT(q.Id) AS QuestionCount
FROM 
    Posts q
JOIN 
    Users u ON q.OwnerUserId = u.Id
WHERE 
    q.PostTypeId = 1 -- Only for questions
GROUP BY 
    u.Id;
