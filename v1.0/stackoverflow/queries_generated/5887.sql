WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score > 5
),
MostCommented AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(mc.TotalComments, 0) AS TotalComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostCommented mc ON rp.PostId = mc.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TotalComments,
    tp.OwnerDisplayName,
    tp.CreationDate
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 5
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
