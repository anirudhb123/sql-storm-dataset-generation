WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (1, 2, 4, 5, 6) THEN 1 END) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.Upvotes,
    us.Downvotes,
    us.GoldBadges,
    us.SilverBadges,
    us.AverageScore,
    COALESCE(phd.ClosedDate, 'No Closure') AS LastClosed,
    COALESCE(phd.ReopenedDate, 'Never Reopened') AS LastReopened,
    phd.EditCount
FROM UserStats us
LEFT JOIN PostHistoryDetails phd ON us.UserId IN (
    SELECT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM PostHistory)
)
WHERE us.PostCount > 10
ORDER BY us.AverageScore DESC, us.Upvotes DESC;
