
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViews,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    mau.DisplayName,
    mau.PostCount,
    mau.QuestionCount,
    mau.AnswerCount,
    mau.TotalScore,
    mau.TotalViews,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
     FROM Posts p 
     JOIN (
         SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM (
             SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
     ) AS tag ON t.TagName = tag.TagName 
     WHERE p.OwnerUserId = mau.UserId) AS MostUsedTags
FROM 
    MostActiveUsers mau
WHERE 
    mau.UserRank <= 10
ORDER BY 
    mau.UserRank;
