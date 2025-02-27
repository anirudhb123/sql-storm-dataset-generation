WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(DATEDIFF(NOW(), p.CreationDate)) AS AveragePostAge
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
BadgesSummary AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        p.Title,
        max(CASE WHEN pht.Name = 'Edit Title' THEN ph.CreationDate END) AS LastEditDate,
        SUM(CASE WHEN pht.Name = 'Post Closed' THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN pht.Name = 'Post Reopened' THEN 1 ELSE 0 END) AS ReopenCount
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId, p.Title
)
SELECT
    ps.UserId,
    ps.DisplayName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AveragePostAge,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    ph.PostId,
    ph.Title AS PostTitle,
    ph.LastEditDate,
    ph.CloseCount,
    ph.ReopenCount,
    CASE 
        WHEN ph.CloseCount > 0 THEN 'Closed'
        WHEN ph.ReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM UserPostStats ps
LEFT JOIN BadgesSummary bs ON ps.UserId = bs.UserId
LEFT JOIN PostHistoryDetails ph ON ph.PostId IN (
    SELECT DISTINCT PostId
    FROM Posts
    WHERE OwnerUserId = ps.UserId
)
ORDER BY ps.TotalScore DESC, ps.TotalPosts DESC, ps.AveragePostAge ASC;
