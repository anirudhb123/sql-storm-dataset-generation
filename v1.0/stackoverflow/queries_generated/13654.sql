-- SQL query for performance benchmarking on Stack Overflow schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(c.Score) AS CommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
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
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.TotalBounties,
    us.CommentScore,
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score AS PostScore,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId
ORDER BY 
    us.Reputation DESC, 
    ps.Score DESC;
