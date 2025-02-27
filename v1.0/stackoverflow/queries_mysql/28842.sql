
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS PostTypeNames,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
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
        GROUP_CONCAT(c.Text SEPARATOR '; ') AS Comments
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
