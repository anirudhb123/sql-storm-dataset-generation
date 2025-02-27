
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, u.DisplayName
),
RecentPostHistories AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate, 
        PHT.Name AS ActionType,
        COUNT(*) AS ActionCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        ph.PostId, ph.CreationDate, PHT.Name
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(DISTINCT TRIM(REGEXP_REPLACE(tag, '<([^>]+)>', ''))) AS CleanedTags
    FROM 
        Posts p
    CROSS JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p
         INNER JOIN (SELECT @row_num := @row_num + 1 AS n FROM 
                     (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                      SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
                      SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
                     (SELECT @row_num := 0) t2) n 
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag_list
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    pt.CleanedTags,
    rp.AnswerCount,
    COALESCE(SUM(rph.ActionCount), 0) AS RecentActionCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistories rph ON rp.PostId = rph.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.rn = 1 
GROUP BY 
    rp.PostId, rp.Title, rp.Body, pt.CleanedTags, rp.AnswerCount
ORDER BY 
    RecentActionCount DESC, rp.AnswerCount DESC
LIMIT 10;
