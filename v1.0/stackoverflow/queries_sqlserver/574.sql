
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - DATEADD(year, 1, 0)
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, CreationDate, OwnerReputation 
    FROM 
        RankedPosts 
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    (SELECT AVG(ViewCount)
     FROM Posts
     WHERE CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - DATEADD(year, 1, 0)) AS AvgViews,
    COALESCE((SELECT COUNT(DISTINCT c.Id)
              FROM Comments c
              WHERE c.PostId IN (SELECT PostId FROM TopPosts)), 0) AS TotalComments,
    CASE 
        WHEN tp.Score > (SELECT AVG(Score) FROM TopPosts) THEN 'Above Average'
        WHEN tp.Score = (SELECT AVG(Score) FROM TopPosts) THEN 'Average'
        ELSE 'Below Average'
    END AS ScoreComparison
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.CreationDate > tp.CreationDate
    AND ph.PostHistoryTypeId IN (10, 11, 12) 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
