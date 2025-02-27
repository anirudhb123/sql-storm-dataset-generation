-- Performance benchmarking query for StackOverflow schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE((SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (8, 9)), 0) AS TotalBounty,
        COALESCE(ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600.0, 2), 0) AS AgeInHours
    FROM 
        Posts p
)

SELECT
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.TotalBadges,
    us.UpVotes,
    us.DownVotes,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.TotalBounty,
    ps.AgeInHours
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.Reputation DESC, ps.Score DESC
LIMIT 100;
