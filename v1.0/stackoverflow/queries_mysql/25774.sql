
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title,
           p.Tags,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT rp.Id, 
           rp.Title,
           rp.Tags,
           rp.CreationDate,
           rp.Score,
           rp.ViewCount
    FROM RankedPosts rp
    WHERE rp.rn <= 5 
),
PostScoreSummary AS (
    SELECT 
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        COUNT(fp.Id) AS QuestionCount,
        SUM(fp.Score) AS TotalScore,
        AVG(fp.ViewCount) AS AverageViewCount
    FROM FilteredPosts fp
    JOIN Posts p ON fp.Id = p.Id
    JOIN (
        SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, ',', nums.n), ',', -1)) AS TagName
        FROM (
            SELECT a.N + b.N * 10 + 1 n
            FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) nums
        WHERE nums.n <= 1 + (LENGTH(fp.Tags) - LENGTH(REPLACE(fp.Tags, ',', '')))
    ) AS t ON FIND_IN_SET(t.TagName, fp.Tags)
    GROUP BY fp.Id, fp.Title, fp.Tags, fp.CreationDate, fp.Score, fp.ViewCount
)
SELECT 
    ps.Tags,
    ps.QuestionCount,
    ps.TotalScore,
    ps.AverageViewCount,
    CASE 
        WHEN ps.QuestionCount > 10 THEN 'High Engagement'
        WHEN ps.QuestionCount > 5 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM PostScoreSummary ps
ORDER BY ps.TotalScore DESC;
