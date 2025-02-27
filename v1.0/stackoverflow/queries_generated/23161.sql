WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        LEAD(p.CreationDate) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS NextPostDate
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        p.Title,
        COUNT(*) AS CloseReasonCount
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId, CloseDate, p.Title
    HAVING COUNT(*) >= 2
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges, 
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges, 
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(b.Class = 1) > 0 OR COUNT(DISTINCT p.Id) > 5 -- Users must have Gold badges or more than 5 posts
),
FinalOutput AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges,
        COALESCE(rp.PostId, 0) AS RecentPostId,
        COALESCE(rp.Title, 'No Recent Post') AS RecentPostTitle,
        COALESCE(CAST(rp.ViewCount AS VARCHAR), '0') || ' views' AS RecentPostViews,
        COALESCE(rp.NextPostDate, 'No Next Post') AS UpcomingPostDate,
        COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount
    FROM UserStats up
    LEFT JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.UserPostRank = 1
    LEFT JOIN ClosedPosts cp ON up.UserId = cp.PostId
)
SELECT 
    UserId, 
    DisplayName, 
    GoldBadges, 
    SilverBadges, 
    BronzeBadges, 
    RecentPostId, 
    RecentPostTitle, 
    RecentPostViews, 
    UpcomingPostDate,
    CASE 
        WHEN CloseReasonCount > 0 THEN 'Has Closed Posts' 
        ELSE 'No Closed Posts' 
    END AS PostClosureStatus
FROM FinalOutput
WHERE GoldBadges > 0 AND TotalPosts >= 5
ORDER BY TotalViews DESC, CloseReasonCount DESC, UserId ASC
LIMIT 100;
