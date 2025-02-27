
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
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    OUTER APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.TagName
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 month'
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
        ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '2 weeks'
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
