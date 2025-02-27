WITH UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS Upvotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS TotalBadgeClass
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosureDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    SUM(pd.ViewCount) AS TotalViews,
    SUM(pb.BadgeCount) AS TotalBadges,
    SUM(COALESCE(phs.EditCount, 0)) AS TotalEdits,
    SUM(COALESCE(phs.ClosureDate IS NOT NULL, 0)) AS TotalClosedPosts
FROM Users u
JOIN PostDetails pd ON u.Id = pd.OwnerUserId
JOIN UserBadges pb ON u.Id = pb.UserId
LEFT JOIN PostHistoryStats phs ON pd.PostId = phs.PostId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
ORDER BY TotalPosts DESC, TotalViews DESC;
