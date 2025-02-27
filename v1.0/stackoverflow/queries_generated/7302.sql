WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, Score, OwnerDisplayName, CommentCount, VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.*, 
    pt.Name AS PostTypeName, 
    bh.Name AS BadgeName,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = t.PostId) AS EditHistoryCount
FROM 
    TopPosts t
LEFT JOIN 
    PostTypes pt ON t.PostId = (SELECT p.Id FROM Posts p WHERE p.Id = t.PostId AND p.PostTypeId = pt.Id LIMIT 1)
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId) 
LEFT JOIN 
    PostHistoryTypes bh ON b.Class = bh.Id
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
