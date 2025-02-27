WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
),
PostDetail AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.OwnerDisplayName,
        tp.CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE(MAX(v.CreationDate), '1970-01-01'::timestamp) AS LastVoteDate
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostsTags pt ON tp.PostId = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.CommentCount
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.Tags,
    pd.LastVoteDate,
    CASE 
        WHEN pd.LastVoteDate >= NOW() - INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivity
FROM 
    PostDetail pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
