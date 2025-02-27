
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.PostTypeId = 1
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    pt.Tag,
    ph.HistoryCount,
    ph.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
