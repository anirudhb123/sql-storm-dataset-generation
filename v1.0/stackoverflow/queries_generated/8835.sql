WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        p.TagCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        Score, 
        ViewCount,
        OwnerName,
        CommentCount,
        ScoreRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    tp.CommentCount,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate,
    JSON_AGG(DISTINCT bh.Name) AS Badges
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerName, tp.CommentCount, ph.Comment, ph.CreationDate
ORDER BY 
    tp.Score DESC;
