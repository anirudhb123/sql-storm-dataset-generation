WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosureChanges,
        MAX(p.CreationDate) AS RecentActivity,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostWithOwners AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        ps.CommentCount,
        ps.ClosureChanges,
        ps.RecentActivity,
        ps.Upvotes,
        ps.Downvotes,
        CASE 
            WHEN ps.Upvotes > ps.Downvotes THEN 'Positive'
            WHEN ps.Upvotes < ps.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM Posts p
    JOIN PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
FilteredPosts AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY Sentiment ORDER BY RecentActivity DESC) AS RowNum
    FROM PostWithOwners
    WHERE ClosureChanges = 0 -- Exclude closed posts
),
TopPosts AS (
    SELECT *
    FROM FilteredPosts
    WHERE RowNum <= 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.Sentiment,
    COALESCE(NULLIF(tp.RecentActivity, '1970-01-01'), 'N/A') AS FormattedRecentActivity
FROM TopPosts tp
ORDER BY tp.Sentiment DESC, tp.RecentActivity DESC
OPTION (RECOMPILE);
