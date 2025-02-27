WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS MostRecentPost
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '1 year')
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ps.PostCount,
        ps.PositivePosts,
        ps.NegativePosts,
        ps.AvgViews,
        ps.MostRecentPost
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.PostCount,
    ur.PositivePosts,
    ur.NegativePosts,
    ur.AvgViews,
    ur.MostRecentPost,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'Reputation unknown'
        WHEN ur.Reputation < 100 THEN 'Low Reputation'
        WHEN ur.Reputation BETWEEN 100 AND 999 THEN 'Moderate Reputation'
        ELSE 'High Reputation'
    END AS ReputationLevel,
    CASE 
        WHEN ur.MostRecentPost IS NULL THEN 'No Recent Activity'
        WHEN ur.MostRecentPost < (NOW() - INTERVAL '3 months') THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    UserReputation ur
WHERE 
    ur.BadgeCount >= 5 OR (ur.PostCount > 10 AND ur.Reputation >= 100)
ORDER BY 
    ur.Reputation DESC, ur.BadgeCount DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- In case of NULL handling, using NULLIF to ensure divide by zero errors are safely handled.
WITH PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        COALESCE(NULLIF(AVG(p.ViewCount), 0), 1) AS AvgViews -- Avoiding NULL for AvgViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'))::int[]
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 0
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.PositiveVotes,
    pt.NegativeVotes,
    pt.AvgViews,
    CASE 
        WHEN pt.AvgViews < 50 THEN 'Low Engagement'
        WHEN pt.AvgViews BETWEEN 50 AND 200 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM 
    PopularTags pt
WHERE 
    pt.TotalViews > 1000
ORDER BY 
    pt.TotalViews DESC, pt.PostCount DESC
LIMIT 5;

-- Example of a subquery using EXISTS to find users with qualified criteria.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation
FROM 
    Users u
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id AND 
              p.CreationDate > (NOW() - INTERVAL '2 months') AND 
              p.Score
