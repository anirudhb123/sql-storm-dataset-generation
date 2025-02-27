-- Performance benchmarking query for Stack Overflow schema
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON u.Id = c.UserId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
        LEFT JOIN Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    GROUP BY 
        p.Id
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    ua.UserId,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.Score,
    vs.UpVotes,
    vs.DownVotes,
    ps.Tags
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ps.PostId IN (SELECT PostId FROM Votes WHERE UserId = ua.UserId)
LEFT JOIN 
    VoteSummary vs ON ps.PostId = vs.PostId
ORDER BY 
    ua.Reputation DESC, ps.ViewCount DESC
LIMIT 100;
