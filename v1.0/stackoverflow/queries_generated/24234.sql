WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
BadBadges AS (
    SELECT 
        u.Id AS UserId,
        CASE 
            WHEN SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) >= 5 THEN 'Super Gold'
            WHEN SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) >= 10 THEN 'Silver Star'
            ELSE NULL
        END AS BadgeCategory
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Rank,
    COALESCE(ubs.BadgeCount, 0) AS BadgeCount,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    CASE 
        WHEN ps.ViewRank IS NOT NULL AND ps.ViewRank <= 3 THEN 'Top Viewer'
        ELSE 'Regular Viewer'
    END AS ViewerStatus,
    bb.BadgeCategory
FROM 
    Users u
LEFT JOIN 
    UserBadgeStats ubs ON u.Id = ubs.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    BadBadges bb ON u.Id = bb.UserId
WHERE 
    COALESCE(ubs.BadgeCount, 0) > 0
OR 
    COALESCE(ps.PostCount, 0) > 1
ORDER BY 
    u.DisplayName ASC;

This SQL query combines various constructs to yield insights into users' activity, their badges, and statistics related to posts they have created. Here's a breakdown of its components:

1. **Common Table Expressions (CTEs)**:
   - `UserBadgeStats`: Summarizes user badges and categorizes them by class (Gold, Silver, Bronze).
   - `PostStats`: Aggregates post metrics for each user, such as post count and total views, and ranks them based on views.
   - `BadBadges`: Identifies users with an excessive number of specific badge types.

2. **Outer Joins**: The use of `LEFT JOIN` ensures that even users without badges or posts are included in the final results.

3. **Conditional Logic**: The query employs `CASE` statements to categorize users based on their badge count and viewing activity.

4. **Null Handling**: The `COALESCE` function is used to handle NULL values gracefully, ensuring that counts and metrics default to zero if no data is found for a user.

5. **Complex Predicates**: The `WHERE` clause filters users based on their activity and badge achievement.

6. **Window Functions**: The use of `ROW_NUMBER()` allows ranking users based on their views, showing top viewers distinctly.

7. **String expressions**: This query constructs text-based categorizations, indicating the status of users based on their activities.

The query thus not only checks for active users with badges but also thrives on reporting their contributions effectively while allowing for nuanced data analysis based on combined insights.
