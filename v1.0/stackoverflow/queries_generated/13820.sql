-- Performance Benchmarking Query
-- This query retrieves metrics on posts, including average scores, views, and the number of related comments
-- It also aggregates user data to analyze reputation and engagement

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), '1900-01-01') AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR  -- Filter for the past year
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.PostTypeId,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    um.Reputation AS UserReputation,
    um.BadgeCount,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    pm.LastVoteDate
FROM 
    PostMetrics pm
JOIN 
    Users u ON pm.UserId = u.Id  -- Assuming a relationship exists between posts and users
JOIN 
    UserMetrics um ON u.Id = um.UserId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;  -- Order by score and view count for better analysis
