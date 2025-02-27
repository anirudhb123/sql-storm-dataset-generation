WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.VoteCount,
    (SELECT STRING_AGG(Name, ', ') FROM Tags t WHERE t.WikiPostId = pd.PostId) AS AssociatedTags
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
