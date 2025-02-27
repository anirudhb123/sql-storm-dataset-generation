WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
        AND p.Score > 0
),

TagDetails AS (
    SELECT 
        PostId,
        STRING_AGG(TRIM(BOTH '<>' FROM unnest(string_to_array(Tags, '>'))) , ', ') AS Tags
    FROM 
        Posts
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.PostType,
    td.Tags,
    COUNT(c.Id) AS CommentCount,
    MAX(b.Date) AS LastBadgeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    TagDetails td ON td.PostId = rp.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts by score per post type
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, 
    rp.ViewCount, rp.Score, rp.OwnerDisplayName, 
    rp.PostType, td.Tags
ORDER BY 
    rp.PostType, rp.Score DESC;
