
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        (
            SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', numbers.n), '>', -1) AS tag
            FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            WHERE CHAR_LENGTH(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2)) - CHAR_LENGTH(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>', '')) >= numbers.n - 1
        ) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.Tags,
    phs.EditCount,
    phs.CloseCount,
    phs.ReopenCount
FROM 
    RankedPosts rp
JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.CreationDate DESC;
