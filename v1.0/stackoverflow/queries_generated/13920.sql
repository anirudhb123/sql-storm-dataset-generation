-- Performance Benchmarking Query

SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount, -- UpVotes
    SUM(v.VoteTypeId = 3) AS DownVoteCount, -- DownVotes
    AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    MAX(p.CreationDate) AS LastActivePostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
