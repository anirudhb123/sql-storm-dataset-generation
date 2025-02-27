
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS tag
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 AS n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                     UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
                     UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
               CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                     UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
                     UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', ''))) 
        ) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(*) AS EditCount,
        GROUP_CONCAT(CONCAT(ph.UserDisplayName, ': ', ph.Comment) SEPARATOR ' | ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS ClosedDate,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.RankByViews,
    rp.Tags,
    rph.LastEdited,
    rph.EditCount,
    rph.EditComments,
    cp.ClosedDate,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankByViews <= 5 
ORDER BY 
    rp.OwnerUserId, rp.ViewCount DESC;
