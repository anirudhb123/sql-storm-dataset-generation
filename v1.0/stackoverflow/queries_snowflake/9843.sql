
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)

SELECT 
    r.Author,
    COUNT(DISTINCT r.PostId) AS TotalPosts,
    SUM(r.Score) AS TotalScore,
    AVG(r.ViewCount) AS AverageViews,
    LISTAGG(CONCAT(r.Title, ' (Score: ', r.Score, ')'), ', ') WITHIN GROUP (ORDER BY r.Score DESC) AS PostTitles
FROM 
    RankedPosts r
WHERE 
    r.Rank <= 5
GROUP BY 
    r.Author
ORDER BY 
    TotalScore DESC
LIMIT 10;
