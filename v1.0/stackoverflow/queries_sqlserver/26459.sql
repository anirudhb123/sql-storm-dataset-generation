
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(DAY, -90, '2024-10-01') AS DATE)
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
    GROUP BY 
        Tags
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 24) THEN 1 END) AS EditCount 
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts rp ON ph.PostId = rp.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    th.PostCount,
    pha.LastEditDate,
    pha.EditCount
FROM 
    RankedPosts rp
JOIN 
    TopTags th ON rp.Tags = th.Tags
JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    th.PostCount DESC, rp.Score DESC;
