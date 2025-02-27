WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(AVG(c.Score), 0) AS AverageCommentScore,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score > 0
    GROUP BY p.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount
    FROM PostHistory ph
    INNER JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    ORDER BY u.Reputation DESC
    LIMIT 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AverageCommentScore,
    fp.OwnerDisplayName,
    fp.TotalComments,
    phs.HistoryTypes,
    phs.HistoryCount,
    uvc.VoteCount AS UserVoteCount,
    tu.UserRank
FROM FilteredPosts fp
JOIN PostHistorySummary phs ON fp.PostId = phs.PostId
LEFT JOIN UserVoteCounts uvc ON fp.OwnerDisplayName = uvc.UserId
JOIN TopUsers tu ON fp.OwnerDisplayName = tu.DisplayName
WHERE 
    fp.TotalComments > 5
    AND (fp.AverageCommentScore IS NULL OR fp.AverageCommentScore > 1)
ORDER BY fp.CreationDate DESC;
