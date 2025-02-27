-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves a benchmark of various metrics on posts, users, votes, and comments
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.UpVotes,
    pm.DownVotes,
    pm.CommentCount,
    um.UserId,
    um.DisplayName AS OwnerDisplayName,
    um.Reputation AS OwnerReputation,
    um.PostCount AS OwnerPostCount,
    um.BadgeCount AS OwnerBadgeCount
FROM 
    PostMetrics pm
JOIN 
    Users um ON pm.PostId = um.Id
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
