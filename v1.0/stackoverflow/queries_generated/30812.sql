WITH RECURSIVE UserPostCount AS (
    SELECT
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM Posts
    GROUP BY OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        up.PostCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN UserPostCount up ON u.Id = up.OwnerUserId
    WHERE u.Reputation IS NOT NULL
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= DATEADD(MONTH, -6, CURRENT_TIMESTAMP)
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.CreationDate,
    ru.Location,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, '') AS BadgeNames,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    rp.PostType AS RecentPostType
FROM RankedUsers ru
LEFT JOIN UserBadges ub ON ru.Id = ub.UserId
LEFT JOIN RecentPosts rp ON ru.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
WHERE ru.PostCount > 5
ORDER BY ru.ReputationRank, ru.Reputation DESC;

This SQL query incorporates several advanced constructs such as recursive CTEs to count user posts, window functions for ranking users based on reputation, and selection of recent posts per user. It also includes join logic to attach badge information and filters to refine results. The presence of a COALESCE function handles potential NULL values elegantly, ensuring that even users without badges or recent posts appear in the output with default values.
