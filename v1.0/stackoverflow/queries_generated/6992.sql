WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    pt.Name AS PostType
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)
WHERE 
    u.Reputation > 1000
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
