-- Performance benchmarking query for the Stack Overflow schema

WITH PostStats AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation,
        SUM(p.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostStats ps ON ps.PostId = p.Id
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalReputation,
    us.TotalViews,
    us.TotalPostScore
FROM 
    PostStats ps
JOIN 
    Users u ON u.Id = ps.OwnerUserId
JOIN 
    UserStats us ON us.UserId = u.Id
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
