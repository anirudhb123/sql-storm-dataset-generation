WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount
    FROM 
        RankedPosts p
    WHERE 
        p.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    bt.Name AS BadgeName,
    count(v.Id) AS VoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges bt ON tp.OwnerDisplayName = bt.UserId
LEFT JOIN 
    Votes v ON tp.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod (upvotes)
WHERE 
    bt.Class = 1 -- Gold badge
GROUP BY 
    tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.ViewCount, bt.Name
ORDER BY 
    tp.Score DESC;
