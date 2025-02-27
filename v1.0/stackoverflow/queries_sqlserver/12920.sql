
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(MAX(v.CreationDate), CAST('1900-01-01' AS DATE)) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AnswerCount,
    ps.LastVoteDate,
    CASE 
        WHEN ps.Score > 0 THEN 'Positive'
        WHEN ps.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreType
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
