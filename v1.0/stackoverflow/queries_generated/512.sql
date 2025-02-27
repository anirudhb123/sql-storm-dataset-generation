WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        COUNT(*) AS CloseReasonCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.CreationDate, ph.UserId, ph.Comment
)
SELECT 
    u.UserId,
    u.DisplayName,
    us.BadgeCount,
    us.TotalViews,
    us.TotalPosts,
    us.TotalScore,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    SUM(COALESCE(pi.CommentCount, 0)) AS TotalComments,
    SUM(COALESCE(pi.VoteCount, 0)) AS TotalVotes,
    COALESCE(cp.CloseReasonCount, 0) AS TotalClosedPosts
FROM UserStats us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN RankedPosts rp ON u.Id = rp.PostOwnerUserId
LEFT JOIN PostInteractions pi ON pi.PostId = rp.Id
LEFT JOIN ClosedPosts cp ON rp.Id = cp.PostId
WHERE us.TotalPosts > 0
GROUP BY u.UserId, u.DisplayName, us.BadgeCount, us.TotalViews, us.TotalPosts, us.TotalScore, cp.CloseReasonCount
HAVING SUM(COALESCE(pi.CommentCount, 0)) > 10 OR COALESCE(cp.CloseReasonCount, 0) > 0
ORDER BY us.TotalScore DESC, us.TotalPosts DESC;
