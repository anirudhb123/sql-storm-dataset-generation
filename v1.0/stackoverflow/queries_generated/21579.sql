WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.TotalBounty,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN rp.TotalBounty > 0 THEN 'Bounty Awarded'
        ELSE 'No Bounty'
    END AS BountyStatus,
    COALESCE(pht.Name, 'No History') AS LastHistoryType,
    EXTRACT(YEAR FROM rp.CreationDate) AS PostYear
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId 
    AND ph.Id = (SELECT MAX(Id) FROM PostHistory WHERE PostId = rp.PostId)
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE rp.Rank <= 5
ORDER BY rp.ViewCount DESC, rp.Score DESC;

-- Additional filtering for posts with special conditions
-- Combining results with UNION to display any 'popular' posts with unjustly high scores (potential spam)
UNION ALL

SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    0 AS TotalBounty,
    u.DisplayName AS OwnerDisplayName,
    'Potential Spam' AS BountyStatus,
    NULL AS LastHistoryType,
    EXTRACT(YEAR FROM p.CreationDate) AS PostYear
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.Score > 100 AND p.ViewCount < 50
GROUP BY p.Id, u.DisplayName
ORDER BY p.Score DESC;

-- Retrieve records where the post has been closed but still has high view counts
SELECT
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    ph.CreationDate AS ClosedOn,
    pht.Name AS CloseReason
FROM Posts p
JOIN PostHistory ph ON p.Id = ph.PostId
JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE p.ClosedDate IS NOT NULL AND p.ViewCount > 100
ORDER BY p.ViewCount DESC;
