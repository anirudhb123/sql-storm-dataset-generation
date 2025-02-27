WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(h.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        PostHistory h ON h.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.AnswerCount,
        ps.LastEditDate,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        PostStatistics ps
    WHERE
        ps.CommentCount > 10 -- Filtering posts with more than 10 comments
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    tp.LastEditDate,
    STRING_AGG(t.TagName, ', ') AS TagList
FROM 
    TopPosts tp
LEFT JOIN 
    Tags t ON tp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE '%' || t.TagName || '%'
    )
WHERE 
    tp.Rank <= 10 -- Getting top 10 posts
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.CommentCount, tp.AnswerCount, tp.LastEditDate
ORDER BY 
    tp.Rank;
