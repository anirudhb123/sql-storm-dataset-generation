
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
        AND p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.AnswerCount,
    t.CommentCount,
    t.FavoriteCount,
    t.OwnerDisplayName,
    COALESCE(AVG(c.Score), 0) AS AverageCommentScore,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
LEFT JOIN 
    Votes v ON t.PostId = v.PostId AND v.VoteTypeId IN (2, 3) 
GROUP BY 
    t.PostId, t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount, t.CommentCount, t.FavoriteCount, t.OwnerDisplayName
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
