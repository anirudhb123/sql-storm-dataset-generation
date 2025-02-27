WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    STY.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes STY ON ph.PostHistoryTypeId = STY.Id
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    LATERAL string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><') AS tag_names(tag) ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_names.tag
WHERE 
    rp.Rank <= 5 -- Limit to top 5 posts per tag
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName, STY.Name
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
