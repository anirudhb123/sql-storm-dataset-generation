WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  -- Top 10 per post type
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Only upvotes
LEFT JOIN 
    LATERAL unnest(string_to_array(p.Tags, ',')) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_name
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
