WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),

PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id
    GROUP BY 
        rp.Id
),

UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)

SELECT 
    ps.Title,
    ps.Tags,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    tuv.UserId,
    tuv.DisplayName AS TopUser,
    tuv.BadgeCount AS TopUserBadges
FROM 
    PostStats ps
JOIN 
    Posts p ON p.Id = ps.Id
LEFT JOIN 
    TopUsers tuv ON tuv.Rank = 1
WHERE 
    ps.Score > 10
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.Id) > 5
    AND (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.Id AND v.VoteTypeId = 2) > (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.Id AND v.VoteTypeId = 3)
ORDER BY 
    ps.Score DESC;

-- The query generates a list of posts with stats and top users having the highest reputation
-- It includes recursive CTEs to get all child posts, computes badge stats for users,
-- and filters posts based on complex business logic. 
-- It utilizes window functions, related subqueries, and sorts output accordingly.
