
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TagAggregates AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS QuestionCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1 >= n.n
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        AvgViewCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagAggregates
    WHERE 
        QuestionCount >= 5 
)
SELECT 
    tt.TagName,
    tt.QuestionCount,
    tt.AvgViewCount,
    tt.TotalScore,
    rp.Title,
    rp.OwnerName,
    rp.CreationDate
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON rp.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    rp.RankByScore <= 3 
ORDER BY 
    tt.Rank, rp.Score DESC;
