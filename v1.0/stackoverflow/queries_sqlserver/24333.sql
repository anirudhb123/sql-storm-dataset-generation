
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.OwnerUserId,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
           AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) * 100 AS UpvotePercentage
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
),

PostHistoryStats AS (
    SELECT ph.PostId,
           MAX(ph.CreationDate) AS LastChange,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 6 THEN 1 END) AS TagEdits,
           STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
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
    GROUP BY u.Id, u.DisplayName
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
           ELSE CAST(rp.UpvotePercentage AS VARCHAR(10)) + '% of votes are upvotes'
       END AS VoteSummary
FROM RankedPosts rp
LEFT JOIN PostHistoryStats ps ON rp.Id = ps.PostId
INNER JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE (ps.ClosureCount > 2 OR rp.UserRank = 1) 
  AND (rp.CommentCount = 0 OR rp.UpvotePercentage IS NOT NULL)
ORDER BY rp.Score DESC, rp.CreationDate DESC;
