-- Performance benchmarking query for Stack Overflow schema

-- Fetching aggregated user reputation and their post counts, joined with post types
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = pt.Id THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
    SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikiExcerptCount,
    SUM(CASE WHEN p.PostTypeId = 5 THEN 1 ELSE 0 END) AS TagWikiCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Analyzing comments on posts for benchmarking comment engagement
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(c.Id) > 0
ORDER BY 
    AverageCommentScore DESC;

-- Analyzing vote distribution on posts for benchmarking engagement
SELECT 
    p.Id AS PostId,
    p.Title,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    UpVotes DESC;
