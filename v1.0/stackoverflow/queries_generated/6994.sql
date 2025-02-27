WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(vote.Score) AS AverageVoteScore,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.LastActivityDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        UserId,
        PostCount,
        TotalBounty,
        AverageVoteScore,
        LastPostDate,
        DATE_PART('year', age(LastPostDate)) AS YearsSinceLastPost
    FROM 
        UserActivity
    WHERE 
        LastPostDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    au.UserId,
    au.PostCount,
    au.TotalBounty,
    au.AverageVoteScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    au.YearsSinceLastPost
FROM 
    ActiveUsers au
JOIN 
    UserBadges ub ON au.UserId = ub.UserId
ORDER BY 
    au.PostCount DESC, 
    ub.BadgeCount DESC
LIMIT 100;
