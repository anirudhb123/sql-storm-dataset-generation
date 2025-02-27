WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id, 
        u.Reputation,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositivePosts, 0) AS PositivePosts,
        COALESCE(ps.NegativePosts, 0) AS NegativePosts,
        COALESCE(ps.AvgViews, 0) AS AvgViews,
        CASE 
            WHEN u.Reputation > 1000 AND ub.TotalBadges > 3 THEN 'Elite'
            WHEN u.Reputation BETWEEN 500 AND 1000 AND ub.TotalBadges > 1 THEN 'Experienced'
            ELSE 'Novice'
        END AS UserLevel
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
ClosingHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVoteCount,
        STRING_AGG(DISTINCT c.Text, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id AND ph.PostHistoryTypeId = 10
    LEFT JOIN Comments c ON ph.PostId = c.PostId
    GROUP BY ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalBadges,
    u.TotalPosts,
    u.PositivePosts,
    u.NegativePosts,
    u.AvgViews,
    u.UserLevel,
    ph.PostId,
    ch.CloseVoteCount,
    ch.CloseReasons
FROM UserReputation u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN ClosingHistory ch ON p.Id = ch.PostId
WHERE (u.Reputation > 100 OR u.TotalBadges > 0)
  AND (ch.CloseVoteCount IS NULL OR ch.CloseVoteCount < 5)
ORDER BY u.Reputation DESC, u.TotalPosts DESC
FETCH FIRST 50 ROWS ONLY;
This SQL query combines several advanced SQL constructs, including Common Table Expressions (CTEs) for aggregating badge and post statistics, correlated subqueries, outer joins, and a conditional string aggregation for closed posts. It assesses user reputation and activity while incorporating logical constraints and grouping. The query fetches a limited number of users classified by a "User Level", and it also accounts for posts that have been closed, showcasing a variety of SQL semantics and constructs along the way.
