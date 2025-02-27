WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        t.TagName,
        tp.PostId,
        tp.Title AS PostTitle,
        tp.CreationDate AS PostCreationDate,
        tp.ViewCount AS PostViewCount,
        tp.Score AS PostScore,
        tp.CommentCount
    FROM 
        TopPosts tp
    JOIN 
        PostsTags pt ON tp.PostId = pt.PostId
    JOIN 
        Tags t ON pt.TagId = t.Id
)
SELECT 
    pd.PostId,
    pd.PostTitle,
    pd.PostCreationDate,
    pd.PostViewCount,
    pd.PostScore,
    pd.CommentCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    Tags t ON pd.PostId = t.Id
GROUP BY 
    pd.PostId, pd.PostTitle, pd.PostCreationDate, pd.PostViewCount, pd.PostScore, pd.CommentCount
ORDER BY 
    pd.PostScore DESC, pd.PostViewCount DESC;
