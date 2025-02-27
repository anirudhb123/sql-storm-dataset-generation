WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.PostCount,
    ru.TotalViews,
    ub.BadgeNames,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    pcr.CloseReasons
FROM 
    RankedUsers ru
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostCloseReasons pcr ON p.Id = pcr.PostId
WHERE 
    (ru.PostCount > 5 OR ub.GoldCount > 0)
    AND (p.LastActivityDate IS NULL OR p.LastActivityDate > NOW() - INTERVAL '30 days')
ORDER BY 
    ru.ViewRank,
    ru.PostCount DESC;
This query combines multiple CTEs (Common Table Expressions) to glean insights about users based on their contributions and badges earned. It ranks users by total views, associates badges, and includes logic for posts that were closed or reopened, while considering recent activity. The use of string aggregation and complex predicates adds depth to the results.
