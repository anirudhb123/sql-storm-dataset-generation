WITH RecursiveUserActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId IN (1, 2) THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        UserId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalViews,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        RecursiveUserActivity ua ON u.Id = ua.UserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000 -- Arbitrary cutoff for active users
)

SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalViews,
    CONCAT('Gold: ', t.GoldBadges, ', Silver: ', t.SilverBadges, ', Bronze: ', t.BronzeBadges) AS BadgeSummary,
    CASE 
        WHEN t.ActivityRank <= 10 THEN 'Top User'
        WHEN t.ActivityRank <= 50 THEN 'Active User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopActiveUsers t
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = t.Id AND p.CreationDate >= NOW() - INTERVAL '30 days'
    )
ORDER BY 
    t.ActivityRank;

WITH RecentPostUpdates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS UpdateDate,
        ph.UserId AS UpdatedBy,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS UpdateRow
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    r.PostId,
    r.Title,
    r.UpdateDate,
    r.UpdatedBy,
    r.PostType
FROM 
    RecentPostUpdates r
WHERE 
    r.UpdateRow = 1; -- Get the most recent update for each post

-- This SQL query combines various constructs to benchmark performance, leveraging CTEs, 
-- window functions, outer joins, complicated predicates, and string expressions.
