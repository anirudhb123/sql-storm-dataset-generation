WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(rp.Tags, '>')) AS tagId ON tagId IS NOT NULL
    JOIN 
        Tags t ON t.Id = tagId::int
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.TagsList,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AverageBounty
FROM 
    PostStats ps
LEFT JOIN 
    Comments c ON ps.PostId = c.PostId
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
WHERE 
    ps.Score > 0
GROUP BY 
    ps.PostId, ps.Title, ps.OwnerDisplayName, ps.Score, ps.ViewCount
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
