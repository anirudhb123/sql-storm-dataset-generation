WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS PostCount, 
        AVG(pt.ViewCount) AS AvgViewCount,
        AVG(pt.Score) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS EditorDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags Edit
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.AvgViewCount AS TagAvgViewCount,
    ts.AvgScore AS TagAvgScore,
    re.EditDate,
    re.EditorDisplayName,
    re.Comment AS EditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
LEFT JOIN 
    Tags t ON rp.Title LIKE '%' || t.TagName || '%'
LEFT JOIN 
    TagStatistics ts ON t.TagName = ts.TagName
WHERE 
    rp.PostRank <= 5 -- Top 5 recent posts per user
ORDER BY 
    rp.CreationDate DESC,
    ts.AvgViewCount DESC;
