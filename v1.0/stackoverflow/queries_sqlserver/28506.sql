
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
        ph.CreationDate >= CAST('2024-10-01' AS DATE) - 30 
    GROUP BY 
        ph.PostId, ph.CreationDate, PHT.Name
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT LTRIM(RTRIM(REPLACE(REPLACE(tag, '<', ''), '>', ''))), ', ') AS CleanedTags
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
