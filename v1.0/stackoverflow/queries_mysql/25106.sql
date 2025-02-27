
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName
),

RecentUpdates AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS UpdateDate,
        ph.Comment AS EditComment,
        p.Title,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 2 WEEK
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    rp.Tags,
    ru.UserDisplayName AS LastEditedBy,
    ru.UpdateDate,
    ru.EditComment,
    ru.PostHistoryType
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUpdates ru ON rp.PostId = ru.PostId
WHERE 
    rp.RankByDate = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
