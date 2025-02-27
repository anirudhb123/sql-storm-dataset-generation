
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Owner,
    tp.CreationDate,
    tp.Score,
    ISNULL(pcm.CommentCount, 0) AS TotalComments
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pcm ON tp.PostId = pcm.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
