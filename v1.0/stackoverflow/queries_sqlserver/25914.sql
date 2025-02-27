
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    CROSS APPLY (
        SELECT tag_name
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag_name
    ) AS tag_name
    JOIN 
        Tags t ON t.TagName = tag_name.value
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN pht.Name = 'Edit Body' THEN 1 END) AS EditBodyCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Owner,
    rp.ViewCount,
    rp.Score,
    pt.TagCount,
    phs.LastClosedDate,
    phs.EditBodyCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTagCounts pt ON rp.PostId = pt.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.Owner, rp.Rank;
