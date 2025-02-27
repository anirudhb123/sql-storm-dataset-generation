WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(b.Id), 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
UserRanked AS (
    SELECT 
        Us.*,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN Us.Upvotes - Us.Downvotes > 0 THEN 1 END ORDER BY Us.Upvotes DESC) AS UpvoteRank
    FROM UserStats Us
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreatedDate,
        p.ViewCount,
        NTILE(4) OVER (ORDER BY p.Score DESC) AS ScoreQuartile,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        DISTINCT p.Id AS ClosedPostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY p.Id
)
SELECT 
    Ur.DisplayName,
    Ur.Reputation,
    Ur.Upvotes,
    Ur.Downvotes,
    Up.RankByReputation,
    Up.UpvoteRank,
    Ap.Title AS ActivePostTitle,
    Ap.ViewCount,
    Ap.ScoreQuartile,
    Ap.CommentCount,
    COALESCE(cp.ClosedPostId, -1) AS ClosedPostId,
    COALESCE(cp.PostHistoryTypes, 'No close history') AS PostCloseHistory
FROM UserRanked Ur
LEFT JOIN ActivePosts Ap ON Ur.UserId = Ap.OwnerUserId 
LEFT JOIN ClosedPosts cp ON Ap.PostId = cp.ClosedPostId
WHERE Ur.BadgeCount > 5 
    AND (Ap.CommentCount > 0 OR Ap.ViewCount > 100)
ORDER BY Ur.Reputation DESC, Up.UpvoteRank
LIMIT 100;

