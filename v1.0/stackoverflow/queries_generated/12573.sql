-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT ba.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges ba ON u.Id = ba.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    us.UserId,
    us.Reputation,
    us.CreationDate,
    us.PostCount,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    ps.PostId,
    ps.Title,
    ps.CreationDate AS PostCreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.Reputation DESC, 
    ps.ViewCount DESC
LIMIT 100;  -- Limits the result to top 100 users based on reputation and post views
