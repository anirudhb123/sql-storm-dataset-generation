WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    pt.Name AS PostType,
    b.Name AS BadgeName,
    COUNT(pp.RelatedPostId) AS RelatedPostsCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = (SELECT id FROM Users WHERE DisplayName = tp.OwnerDisplayName LIMIT 1)
LEFT JOIN 
    PostLinks pp ON tp.PostId = pp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, pt.Name, b.Name
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
