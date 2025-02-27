WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.FavoriteCount,
        COUNT(c.Id) AS CommentTotal,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        PostsTags pt ON tp.PostId = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.FavoriteCount
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.CommentTotal,
    pd.Tags
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
