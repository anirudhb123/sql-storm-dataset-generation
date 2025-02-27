WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        JSON_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 YEAR' 
    GROUP BY 
        p.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.Upvotes,
    rp.Tags,
    CASE 
        WHEN rp.rn = 1 THEN 'New'
        WHEN rp.rn <= 5 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory 
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
