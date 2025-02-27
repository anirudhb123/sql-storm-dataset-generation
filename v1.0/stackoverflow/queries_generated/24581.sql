WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS LastAccountCreate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

PostViewCounts AS (
    SELECT 
        p.OwnerUserId, 
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        MAX(p.CreationDate) AS LatestPostDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW()
    GROUP BY p.Id, p.OwnerUserId, v.VoteCount, v.DownVoteCount
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.UserRank,
    ps.PostId,
    ps.CommentCount,
    pv.TotalViews,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'More Upvotes'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteStatus,
    CASE 
        WHEN ru.Reputation >= 1000 THEN 'High Reputation'
        WHEN ru.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationStatus
FROM RankedUsers ru
LEFT JOIN PostStatistics ps ON ru.UserId = ps.OwnerUserId
LEFT JOIN PostViewCounts pv ON ru.UserId = pv.OwnerUserId
WHERE ru.UserRank <= 50  -- Filter top 50 users by reputation
AND ps.CommentCount > 0   -- Only users who have posts with comments
ORDER BY ru.Reputation DESC, ps.CommentCount DESC;

-- Note: The main query combines several CTEs, computes user statistics, views, 
-- and post-related metrics, while showcasing different SQL constructs including 
-- window functions, outer joins, and case constructs.
