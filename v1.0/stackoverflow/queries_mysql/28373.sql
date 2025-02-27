
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
), TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '<', -1) AS TagName,
            Score
        FROM 
            RankedPosts
        JOIN 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1
    ) AS UnnestedTags
    GROUP BY 
        TagName
), TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.TagName,
    tt.QuestionCount,
    tt.TotalScore,
    CASE
        WHEN tt.QuestionCount > 50 THEN 'Active'
        WHEN tt.QuestionCount > 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS TagActivityStatus
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10 
ORDER BY 
    tt.TotalScore DESC;
