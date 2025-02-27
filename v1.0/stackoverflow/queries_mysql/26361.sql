
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1 AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        TagCount,
        OwnerDisplayName,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
)

SELECT 
    tp.Title,
    tp.Body,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TagCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    COUNT(c.Id) AS TotalComments, 
    SUM(b.Class) AS TotalBadges 
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, 
    tp.ViewCount, tp.Score, tp.AnswerCount, 
    tp.CommentCount, tp.TagCount, tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
