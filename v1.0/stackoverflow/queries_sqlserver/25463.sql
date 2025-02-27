
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankInCategory,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsArray
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS t ON 1=1
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, pt.Name, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.TagsArray,
    COALESCE(ph.Comment, 'No comments about post history') AS HistoryComment
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 
WHERE 
    rp.RankInCategory <= 5 
ORDER BY 
    rp.PostId, rp.RankInCategory;
