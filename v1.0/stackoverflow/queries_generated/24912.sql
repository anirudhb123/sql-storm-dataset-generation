WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        MAX(u.LastAccessDate) AS LastAccess
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS RecentPosts,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate))) AS AvgTimeSinceLastPost 
    FROM Posts 
    WHERE CreationDate >= CURRENT_TIMESTAMP - interval '30 days'
    GROUP BY UserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.UserDisplayName,
        p.Title,
        COUNT(DISTINCT ph.Id) AS ClosureCount,
        STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId 
    JOIN CloseReasonTypes ct ON ph.Comment::int = ct.Id 
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY p.Id, ph.UserDisplayName, p.Title
),
ScoreRanking AS (
    SELECT 
        UserId,
        SUM(Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(Score) DESC) AS ScoreRank
    FROM Posts
    GROUP BY UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    ra.RecentPosts,
    ra.AvgTimeSinceLastPost,
    cp.PostId AS ClosedPostId,
    cp.Title AS ClosedPostTitle,
    cp.ClosureCount,
    cp.CloseReasons,
    sr.TotalScore,
    sr.ScoreRank
FROM UserStats us
LEFT JOIN RecentActivity ra ON us.UserId = ra.UserId
LEFT JOIN ClosedPosts cp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId LIMIT 1)
LEFT JOIN ScoreRanking sr ON us.UserId = sr.UserId
WHERE us.Reputation > 1000
AND (us.TotalPosts IS NOT NULL OR (ra.RecentPosts > 5 AND sr.TotalScore > 50))
ORDER BY us.Reputation DESC, sr.ScoreRank ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM Users) / 10;
