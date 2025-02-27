WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Count only Upvotes
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.RankPerUser,
        rp.VoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteCount >= 5  -- Only include posts with at least 5 upvotes
)
SELECT 
    tp.Id,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.Id) AS CommentCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
