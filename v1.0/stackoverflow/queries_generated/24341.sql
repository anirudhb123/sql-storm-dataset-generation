WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.Score > 0
),

TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t 
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),

TagRanking AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagPostCounts
    WHERE PostCount > 0
),

ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId, ph.CreationDate
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    t.TagName,
    tr.TagRank,
    cph.CloseReasons,
    CASE 
        WHEN cph.CloseReasons IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM RankedPosts rp
LEFT JOIN TagRanking tr ON TRUE -- For adding a join, yielding cartesian if necessary
LEFT JOIN ClosedPostHistories cph ON rp.PostId = cph.PostId
WHERE rp.PostRank <= 5
ORDER BY tr.TagRank, rp.Score DESC, rp.CreationDate DESC;
