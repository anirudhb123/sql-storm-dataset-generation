WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
),
TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(rp.Rank, 0) AS Rank,
    tp.TagName,
    ppc.PostCount,
    rph.EditCount,
    rph.LastEditDate,
    CASE 
        WHEN rph.EditCount > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Tags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(rp.Title, ' ')) -- Tags based on title words
LEFT JOIN 
    TagPostCounts ppc ON t.TagName = ppc.TagName
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 10 -- Top 10 posts by score for each post type
ORDER BY 
    rp.PostId;
