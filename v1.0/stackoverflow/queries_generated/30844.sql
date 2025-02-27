WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        p.LastActivityDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only consider questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.Score,
        p2.AnswerCount,
        p2.ViewCount,
        p2.OwnerUserId,
        p2.LastActivityDate,
        rps.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostStats rps ON p2.ParentId = rps.PostId
)

, UserBadges AS (
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
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.AnswerCount,
    ps.ViewCount,
    ps.LastActivityDate,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RecursivePostStats ps
LEFT JOIN 
    UserBadges ub ON ps.OwnerUserId = ub.UserId
WHERE 
    ps.ViewCount > 50  -- Only consider posts with more than 50 views
ORDER BY 
    ps.Score DESC, 
    ps.LastActivityDate DESC
FETCH FIRST 20 ROWS ONLY;

-- Including a string expression to concatenate badge counts
SELECT 
    CONCAT('User ', ub.UserId, ' has ', ub.BadgeCount, ' badges (', 
             ub.GoldBadges, ' Gold, ', 
             ub.SilverBadges, ' Silver, ', 
             ub.BronzeBadges, ' Bronze)') AS BadgeSummary
FROM 
    UserBadges ub
WHERE 
    ub.BadgeCount > 0;

This query consists of:
1. A recursive CTE (`RecursivePostStats`) to handle hierarchical relationships (questions and their answers).
2. A second CTE (`UserBadges`) to summarize badge counts per user.
3. A main query that joins these two CTEs, retrieves relevant post and user information, and includes filtering and ordering based on specific conditions.
4. A string expression to create a summary of badge counts in a readable format, demonstrating the use of concatenation in SQL.
