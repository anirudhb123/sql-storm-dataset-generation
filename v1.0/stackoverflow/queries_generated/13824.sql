-- Performance Benchmarking Query for StackOverflow Schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COALESCE(AVG(c.Score), 0) AS AvgCommentScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.TotalBounty,
    ps.Title,
    ps.PostTypeId,
    ps.Score,
    ps.ViewCount,
    ps.AvgCommentScore,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseVotes
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId -- Assuming OwnerUserId is the user who created the post
ORDER BY 
    us.Reputation DESC, ps.Score DESC
LIMIT 100; -- Limit to top 100 by reputation
