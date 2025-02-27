WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown' 
            WHEN u.Reputation > 1000 THEN 'High Rep' 
            ELSE 'Low Rep' 
        END AS ReputationCategory
    FROM Users u
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY p.Id, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        ur.Reputation,
        ps.PostId,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        cp.CloseReasons,
        ur.ReputationCategory,
        CASE 
            WHEN ps.TotalBounty IS NULL THEN 0 ELSE ps.TotalBounty END AS EffectiveBounty
    FROM UserReputation ur
    JOIN Posts ps ON ps.OwnerUserId = ur.UserId
    LEFT JOIN ClosedPosts cp ON ps.Id = cp.PostId
    WHERE ur.Ranking <= 50 -- Top 50 Users
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    ReputationCategory,
    SUM(ViewCount) AS TotalViews,
    SUM(CommentCount) AS TotalComments,
    COUNT(PostId) AS TotalPosts,
    MAX(Score) AS HighestPostScore,
    STRING_AGG(DISTINCT CloseReasons, '; ') AS ClosedReasonList
FROM FinalResults
GROUP BY UserId, DisplayName, Reputation, ReputationCategory
HAVING COUNT(PostId) > 0
ORDER BY TotalViews DESC, TotalPosts DESC
LIMIT 10;

This query performs a series of complex operations involving CTEs, window functions, and aggregation to generate insights about user reputation and their posts, including which ones were closed and the reasons for closure. It also infers various metrics such as total views and comments per user, while applying a selection of interesting SQL constructs that address potential corner cases in the relationships between users, posts, comments, and history entries.
