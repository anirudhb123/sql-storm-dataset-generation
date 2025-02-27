WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
)

SELECT 
    tp.Name AS PostType,
    COUNT(rp.Id) AS TotalPosts,
    AVG(rp.ViewCount) AS AverageViews,
    AVG(rp.Score) AS AverageScore,
    SUM(rp.AnswerCount) AS TotalAnswers,
    MAX(rp.ViewCount) AS MaxViewCount,
    MIN(rp.ViewCount) AS MinViewCount
FROM 
    RankedPosts rp
JOIN 
    PostTypes tp ON rp.PostTypeId = tp.Id
WHERE 
    rp.RankScore <= 10 OR rp.RankViews <= 10
GROUP BY 
    tp.Name
ORDER BY 
    TotalPosts DESC;
