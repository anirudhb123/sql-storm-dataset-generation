WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COALESCE(
            (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id AND a.PostTypeId = 2), 0
        ) AS AnswerCount,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0
        ) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerName, AnswerCount, CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.OwnerName, 
    tp.AnswerCount, 
    tp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS Tag) AS t ON tp.PostId = p.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerName, tp.AnswerCount, tp.CommentCount
ORDER BY 
    tp.Score DESC;
