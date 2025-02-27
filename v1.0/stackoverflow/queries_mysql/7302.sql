
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        @rownum := IF(@prev_post_type_id = p.PostTypeId, @rownum + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rownum := 0, @prev_post_type_id := NULL) r
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
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
    PostTypes pt ON t.PostId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId LIMIT 1) 
LEFT JOIN 
    PostHistoryTypes bh ON b.Class = bh.Id
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
