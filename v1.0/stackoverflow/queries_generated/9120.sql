WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplay, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
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
        rp.*, 
        pt.Name AS PostType 
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.ScoreRank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.ViewCount, 
    tp.OwnerDisplay, 
    tp.CommentCount, 
    tp.PostType
FROM 
    TopPosts tp
ORDER BY 
    tp.PostType, 
    tp.Score DESC;
