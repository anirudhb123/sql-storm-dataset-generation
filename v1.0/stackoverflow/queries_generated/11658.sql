-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.CommentCount AS UserCommentCount,
    u.TotalBounties,
    p.PostId,
    p.CommentCount AS PostCommentCount,
    p.VoteCount,
    p.UpvoteCount,
    p.DownvoteCount
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
ORDER BY 
    u.Reputation DESC, u.PostCount DESC;
