WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.LastBadgeDate, '2000-01-01') AS LastBadgeDate,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN UsersWithBadges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(p.Id) > 10
)
SELECT 
    t.DisplayName,
    t.BadgeCount,
    SUM(cp.ViewCount) AS TotalViews,
    SUM(cp.Score) AS TotalScore,
    AVG(cp.ViewCount) AS AverageViewsPerPost,
    COUNT(DISTINCT cp.Id) AS TotalPosts,
    MAX(cp.CreationDate) AS MostRecentPostDate
FROM TopUsers t
JOIN RankedPosts cp ON t.Id = cp.OwnerUserId
LEFT JOIN Comments c ON cp.Id = c.PostId
WHERE t.BadgeCount > 2
GROUP BY t.DisplayName, t.BadgeCount
ORDER BY TotalScore DESC, AverageViewsPerPost DESC
FETCH FIRST 10 ROWS ONLY;
