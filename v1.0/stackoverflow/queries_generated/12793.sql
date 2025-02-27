-- Performance benchmarking query to analyze user activity and post interactions

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT v.Id) AS VotesCast,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.VotesCast,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ps.CommentCount > 0  -- Include only posts that have comments
ORDER BY 
    ua.VotesCast DESC, ua.PostsCreated DESC;  -- Order by votes and posts created for benchmarking
