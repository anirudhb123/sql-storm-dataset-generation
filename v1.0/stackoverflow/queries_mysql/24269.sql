
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBountyAmount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.LastActivityDate > NOW() - INTERVAL 1 MONTH
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.ViewCount
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(DISTINCT ph.UserDisplayName) AS EditorCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        COALESCE(p.DeleteCount, 0) AS DeleteCount,
        COALESCE(p.EditorCount, 0) AS EditorCount,
        r.TagsList,
        r.ViewRank,
        p.FirstCloseDate,
        p.LastCloseDate,
        ((r.ViewCount + COALESCE(p.DeleteCount, 0) * -1) / NULLIF(r.CommentCount, 0)) AS Score 
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostHistoryInfo p ON r.PostId = p.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.ViewCount,
    f.DeleteCount,
    f.EditorCount,
    f.TagsList,
    f.ViewRank,
    f.Score,
    CASE 
        WHEN f.FirstCloseDate IS NOT NULL AND f.LastCloseDate IS NULL THEN 'Open but Closed in Past'
        WHEN f.LastCloseDate IS NOT NULL AND f.FirstCloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Never Closed' 
    END AS ClosedStatus
FROM 
    FinalResults f
WHERE 
    f.Score > 0
ORDER BY 
    f.ViewCount DESC, 
    f.Score DESC
LIMIT 50;
