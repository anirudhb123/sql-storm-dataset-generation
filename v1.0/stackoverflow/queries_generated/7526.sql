WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.PostTypeId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    OwnerDisplayName,
    CommentCount,
    TotalBounties,
    Tags
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, CreationDate ASC;
