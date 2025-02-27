
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
),
RecentUserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        GROUP_CONCAT(DISTINCT crt.Name) AS CloseReasons
    FROM PostHistory ph
    INNER JOIN CloseReasonTypes crt ON CAST(ph.Comment AS UNSIGNED) = crt.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT
    up.Id AS UserId,
    up.DisplayName,
    up.Reputation,
    rps.PostId,
    rps.Title AS RecentPostTitle,
    rps.CreationDate AS RecentPostDate,
    COALESCE(dd.CloseReasonCount, 0) AS ClosedPostCount,
    COALESCE(dd.CloseReasons, '') AS CloseReasons,
    rps.Score AS PostScore,
    rps.ViewCount AS PostViews,
    nus.PostsCount AS UserPostsCount,
    nus.TotalBounties,
    nus.TotalCommentScore
FROM Users up
LEFT JOIN RecentUserStats nus ON up.Id = nus.UserId
LEFT JOIN RankedPosts rps ON rps.Rank <= 5
LEFT JOIN ClosedPosts dd ON dd.PostId = rps.PostId
WHERE up.Reputation > 100 AND nus.TotalBounties > 0
ORDER BY up.Reputation DESC, rps.CreationDate DESC
LIMIT 50;
