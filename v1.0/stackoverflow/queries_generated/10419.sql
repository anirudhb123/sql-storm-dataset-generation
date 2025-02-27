-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves statistics regarding posts, their respective users, and comments made on them, 
-- aimed at assessing the performance across various dimensions.

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, u.Reputation, u.DisplayName
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.PostCreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.VoteCount,
    pm.OwnerDisplayName,
    pm.OwnerReputation,
    um.Reputation AS UserReputation,
    um.BadgeCount AS UserBadgeCount
FROM 
    PostMetrics pm
JOIN 
    UserMetrics um ON pm.OwnerReputation = um.Reputation
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
