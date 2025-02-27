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
        u.Id, u.DisplayName
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        ps.OwnerUserId,
        AVG(ps.Score) AS AvgScore,
        SUM(ps.ViewCount) AS TotalViews,
        COUNT(ps.PostId) AS PostCount
    FROM 
        PostScores ps
    WHERE 
        ps.PostRank <= 5
    GROUP BY 
        ps.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    u.Views,
    u.UpVotes,
    u.DownVotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tp.AvgScore,
    tp.TotalViews,
    tp.PostCount
FROM 
    Users u
LEFT JOIN 
    UserBadgeStats ub ON u.Id = ub.UserId
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
WHERE 
    u.Reputation > 1000
    AND (ub.BadgeCount > 0 OR tp.PostCount > 0)
ORDER BY 
    u.Reputation DESC, 
    COALESCE(tp.AvgScore, 0) DESC;
This SQL query performs the following tasks:

1. **UserBadgeStats CTE**: Computes statistics for users regarding their badges, including counts of gold, silver, and bronze badges.
   
2. **PostScores CTE**: Filters posts created within the last year and ranks the user's posts based on their score.

3. **TopPosts CTE**: Calculates the average score of the top 5 posts for each user, the total views, and the count of those posts.

4. Finally, it selects from the `Users` table, joining with `UserBadgeStats` and `TopPosts`, applying filters for reputation and badge achievements, and ordering the results to highlight the most reputed users. 

The query includes various SQL constructs like CTEs, LEFT JOINs, conditional aggregation, order by clauses, and complex predicates.
