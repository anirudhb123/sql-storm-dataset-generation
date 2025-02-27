WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id, u.DisplayName
),
RecentBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastAwarded
    FROM
        Badges b
    GROUP BY
        b.UserId
)
SELECT
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS PostOwner,
    ra.BadgeCount AS TotalBadges,
    ua.TotalPosts AS UserTotalPosts,
    ua.TotalAnswers AS UserTotalAnswers,
    ua.TotalQuestions AS UserTotalQuestions,
    ua.TotalBounty
FROM
    RankedPosts p
JOIN
    UserActivity ua ON p.OwnerUserId = ua.UserId
LEFT JOIN
    RecentBadges ra ON p.OwnerUserId = ra.UserId
WHERE
    p.RankScore <= 10
    AND (p.Score >= 5 OR p.ViewCount >= 100)
ORDER BY
    p.Score DESC, p.ViewCount DESC;

-- Additional context:
-- This query retrieves the top 10 posts from the past 6 months, ordered by score and view count.
-- It includes user activity statistics for users with reputation above 1000, 
-- as well as information about total awarded badges per user.

