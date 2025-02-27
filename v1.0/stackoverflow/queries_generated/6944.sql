WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerDisplayName 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.Score, 
        tp.ViewCount, 
        tp.OwnerDisplayName, 
        JSON_AGG(t.TagName) AS PostTags
    FROM 
        TopPosts tp
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(p.Tags, '>')) AS TagName
            FROM 
                Posts p 
            WHERE 
                p.Id = tp.PostId
        ) t ON true
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pd.PostId, 
    pd.Title, 
    pd.Score, 
    pd.ViewCount, 
    pd.OwnerDisplayName, 
    pd.PostTags, 
    COUNT(v.Id) AS VoteCount
FROM 
    PostDetails pd
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
WHERE 
    v.CreationDate >= NOW() - INTERVAL '1 month'
GROUP BY 
    pd.PostId, pd.Title, pd.Score, pd.ViewCount, pd.OwnerDisplayName, pd.PostTags
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
