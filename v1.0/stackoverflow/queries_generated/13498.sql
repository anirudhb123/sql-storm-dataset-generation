-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        MAX(v.CreationDate) AS LastVoteDate,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastVoteDate,
    ps.LastCommentDate,
    us.UserId,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation AS OwnerReputation,
    us.BadgeCount AS OwnerBadgeCount,
    us.PostCount AS OwnerPostCount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id  -- Assuming post owner field corresponds to a user
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.CommentCount DESC, ps.VoteCount DESC
LIMIT 100;
