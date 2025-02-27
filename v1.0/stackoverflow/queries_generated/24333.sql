WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.OwnerUserId,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
           AVG(v.VoteTypeId = 2::smallint) OVER (PARTITION BY p.Id) * 100 AS UpvotePercentage
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),

PostHistoryStats AS (
    SELECT ph.PostId,
           MAX(ph.CreationDate) AS LastChange,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS ClosureCount,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 6) AS TagEdits,
           STRING_AGG(DISTINCT pht.Name) AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),

TopUsers AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           SUM(p.Score) AS TotalScore,
           COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId 
    GROUP BY u.Id
)

SELECT rp.Title,
       rp.CreationDate,
       rp.Score,
       ps.LastChange,
       ps.ClosureCount,
       ps.TagEdits,
       tu.DisplayName,
       tu.TotalScore,
       tu.TotalPosts,
       rp.UserRank,
       CASE 
           WHEN rp.UpvotePercentage IS NULL THEN 'No votes found'
           WHEN rp.UpvotePercentage = 100 THEN 'All upvotes'
           ELSE CONCAT(rp.UpvotePercentage, '% of votes are upvotes')
       END AS VoteSummary
FROM RankedPosts rp
LEFT JOIN PostHistoryStats ps ON rp.Id = ps.PostId
INNER JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE (ps.ClosureCount > 2 OR rp.UserRank = 1) 
  AND (rp.CommentCount = 0 OR rp.UpvotePercentage IS NOT NULL)
ORDER BY rp.Score DESC, rp.CreationDate DESC;

-- Additional insights 
SELECT 'Average closure time (in days):' AS Info, 
       AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate)) / 86400) AS AvgClosureTimeDays
FROM Posts p
JOIN PostHistory ph ON p.Id = ph.PostId
WHERE ph.PostHistoryTypeId IN (10, 11)
GROUP BY p.Id
HAVING COUNT(ph.Id) > 0;

This SQL query is designed to aggregate and analyze posts within a specified timeframe while incorporating various SQL constructs such as Common Table Expressions (CTEs) for organizing data. It uses window functions to rank posts by user and calculate percentages of upvotes, along with string aggregation to display unique post history types. The query also handles edge cases and NULL values, providing useful insights about the posts, users, and history while showcasing the complexity of SQL navigation through the schema's relationships.
