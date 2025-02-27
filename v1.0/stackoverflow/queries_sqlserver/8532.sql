
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC, p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '><')) AS t
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.Tags,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top'
        WHEN rp.Rank <= 10 THEN 'Mid'
        ELSE 'Low'
    END AS PopularityRank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
