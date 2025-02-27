WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        *, 
        (Reputation + PostCount * 10 + AnswerCount * 5 + UpVotes * 3 - DownVotes * 2) AS PerformanceScore
    FROM 
        UserReputation
    ORDER BY 
        PerformanceScore DESC
    LIMIT 10
)
SELECT 
    t.DisplayName, 
    t.Reputation, 
    t.PostCount, 
    t.AnswerCount, 
    t.UpVotes, 
    t.DownVotes, 
    th.CreationDate AS LastActivityDate,
    COUNT(DISTINCT c.Id) AS CommentCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes
FROM 
    TopUsers t
LEFT JOIN 
    Posts p ON t.UserId = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT UserId, MAX(LastActivityDate) AS CreationDate
     FROM 
         Posts
     WHERE 
         LastActivityDate IS NOT NULL
     GROUP BY 
         UserId) th ON t.UserId = th.UserId
GROUP BY 
    t.UserId, t.DisplayName, t.Reputation, t.PostCount, t.AnswerCount, t.UpVotes, t.DownVotes, th.CreationDate
ORDER BY 
    t.PerformanceScore DESC;
