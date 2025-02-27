WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10
),
PostSummary AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(cp.ClosedDate, 'No Closure') AS ClosedDate,
        COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
        rp.ViewCount,
        rp.RankScore
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    ps.*,
    CASE 
        WHEN ps.ClosedDate != 'No Closure' THEN 'Closed'
        WHEN ps.RankScore <= 5 THEN 'Top Performers'
        ELSE 'Others' 
    END AS PostCategory
FROM PostSummary ps
WHERE ps.RankScore <= 10
AND ps.ViewCount > 100
ORDER BY ps.CreationDate DESC, ps.RankScore ASC
LIMIT 50;

WITH TagPopularity AS (
    SELECT 
        LOWER(tag.TagName) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags tag
    LEFT JOIN Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY tag.TagName
    HAVING COUNT(p.Id) > 5
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.DisplayName
    ORDER BY PostCount DESC, TotalBounties DESC
    LIMIT 10
)
SELECT 
    tp.TagName,
    tp.PostCount,
    tu.DisplayName,
    tu.PostCount AS UserPostCount,
    tu.TotalBounties
FROM TagPopularity tp
CROSS JOIN TopUsers tu
ORDER BY tp.PostCount DESC, tu.TotalBounties DESC;
