
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
        ph.CreationDate >= DATEADD(DAY, -30, CURRENT_DATE)
    GROUP BY 
        ph.PostId, ph.CreationDate, PHT.Name
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        LISTAGG(DISTINCT TRIM(REGEXP_REPLACE(tag, '<([^>]+)>', '', 'g')), ', ') AS CleanedTags
    FROM 
        Posts p,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag
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
