
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT TRIM(BOTH '<>' FROM tag) AS TagName 
         FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '|', n.n), '|', -1) AS tag 
               FROM (SELECT a.N + b.N * 10 + 1 n 
                     FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a 
                     CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n 
               WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '|', ''))) ) AS tag_array) AS tag_array 
        ) AS t ON t.TagName = TRIM(BOTH '<>' FROM tag_array.TagName)
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredQuestions,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalQuestions,
    us.PositiveScoredQuestions,
    us.NegativeScoredQuestions,
    us.AverageScore,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CreationDate
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000 
AND 
    rp.RankPerUser <= 3 
ORDER BY 
    us.Reputation DESC, rp.Score DESC;
