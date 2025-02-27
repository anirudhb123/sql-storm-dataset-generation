WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '<>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    (SELECT COUNT(DISTINCT b.UserId) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS BadgeCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
