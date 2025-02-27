-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    us.PostCount,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.PostRank
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.PostCount > 0  -- Only users with posts
ORDER BY 
    us.Reputation DESC, ps.PostRank;
