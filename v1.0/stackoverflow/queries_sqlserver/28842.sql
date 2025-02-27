
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Owner,
        PostTypeNames
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Owner,
    tp.PostTypeNames,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.Comments, 'No comments') AS Comments
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
