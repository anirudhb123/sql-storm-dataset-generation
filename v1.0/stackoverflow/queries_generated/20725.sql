WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    p.Title,
    p.CreationDate,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        ELSE ub.BadgeNames
    END AS UserBadges,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN p.Score > 10 THEN 'High Score'
        WHEN p.Score BETWEEN 1 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN p.Title IS NULL THEN 'Untitled Post'
        ELSE p.Title
    END AS TitleOrPlaceholder,
    ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS OverallRank
FROM 
    Posts p
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    PostComments pc ON p.Id = pc.PostId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = p.Id 
        AND v.VoteTypeId = 2
    )
    OR 
    p.Id IN (
        SELECT RelatedPostId 
        FROM PostLinks pl 
        WHERE pl.LinkTypeId = 1 AND pl.PostId IN (
            SELECT PostId FROM RankedPosts WHERE UserPostRank <= 5
        )
    )
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

-- Additional intricate join to handle badge types
SELECT 
    p.Title,
    COUNT(b.Id) AS BadgeClassCount,
    STRING_AGG(DISTINCT bt.Name, ', ') AS BadgeTypeNames
FROM 
    Posts p
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT JOIN 
    PostHistoryTypes bt ON ph.PostHistoryTypeId = bt.Id
WHERE 
    b.Class = 1
GROUP BY 
    p.Id
HAVING 
    COUNT(b.Id) > 1;

This SQL script demonstrates various advanced constructs and complex logic, featuring CTEs for ranking posts and aggregating user badges, conditional logic for score evaluation and title handling, along with intricate joins and subqueries to build an insightful performance benchmark query set.
