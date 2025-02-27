WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT p.Id) OVER (PARTITION BY u.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL AND 
        u.Location IS NOT NULL
),
RecentComments AS (
    SELECT 
        c.UserId,
        c.CreationDate,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    WHERE 
        c.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days') 
    GROUP BY 
        c.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    ru.PostCount,
    COALESCE(rc.TotalComments, 0) AS RecentCommentsCount,
    ub.BadgeNames,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedUsers ru
LEFT JOIN 
    RecentComments rc ON ru.UserId = rc.UserId
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
WHERE 
    (ru.Reputation > 1000 AND ru.ReputationRank <= 3) 
    OR (ru.ReputationRank IS NULL AND ru.PostCount = 0)
ORDER BY 
    ru.Reputation DESC, ru.Location DESC NULLS LAST
LIMIT 100;

-- Bizarre logic: Include an example of fuzziness in the display.
SELECT 
    UserId,
    DisplayName || ' (' || COALESCE(BadgeNames, 'No Badges') || ')' AS UserDisplayName,
    CASE 
        WHEN Reputation > 5000 THEN 
            'Elite' 
        WHEN Reputation BETWEEN 1000 AND 5000 THEN 
            'Experienced' 
        ELSE 
            'Novice' 
    END AS UserLevel
FROM ({
    SELECT 
        ru.UserId, 
        ru.DisplayName, 
        ub.BadgeNames
    FROM 
        RankedUsers ru
    LEFT JOIN 
        UserBadges ub ON ru.UserId = ub.UserId
}) AS FuzzyDisplay
ORDER BY 
    UserLevel DESC, UserId;

This SQL query includes several complex constructs such as CTEs (Common Table Expressions) that are correlated and use various aggregates, outer joins, and filtering based on null logic. It showcases various user metrics from the `Users`, `Posts`, `Comments`, and `Badges` tables and provides insights on user engagement with fuzzy display output semantics. The usage of `STRING_AGG`, `ROW_NUMBER`, and conditional logic illustrate advanced SQL concepts.
