-- Performance benchmarking query for StackOverflow schema

WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(Id) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.LastActivityDate
FROM 
    UserVoteStats u
JOIN 
    PostStats p ON u.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    u.TotalVotes DESC, p.LastActivityDate DESC;
