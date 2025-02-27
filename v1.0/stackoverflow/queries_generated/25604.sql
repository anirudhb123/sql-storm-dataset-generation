WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagId 
        ON t.Id = (SELECT Id FROM Tags WHERE TagName = tagId)
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.Tags,
    ra.UserDisplayName AS LastEditor,
    ra.EditDate,
    ra.Comment,
    ra.Text AS EditDetails,
    COUNT(*) OVER (PARTITION BY rp.PostId) AS EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;
