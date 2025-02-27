
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS RankByTag
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate > NOW() - INTERVAL 1 YEAR 
        AND P.ViewCount > 100
),
TagDetails AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT RP.PostId) AS QuestionCount,
        SUM(RP.AnswerCount) AS TotalAnswers,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.ViewCount) AS TotalViews
    FROM 
        RankedPosts RP
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(RP.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(RP.Tags) - CHAR_LENGTH(REPLACE(RP.Tags, '><', '')) >= numbers.n - 1) AS T
    ON true
    GROUP BY 
        T.TagName
)
SELECT 
    TD.TagName,
    TD.QuestionCount,
    TD.TotalAnswers,
    TD.AverageScore,
    TD.TotalViews
FROM 
    TagDetails TD
WHERE 
    TD.QuestionCount >= 5 
ORDER BY 
    TD.TotalAnswers DESC,
    TD.AverageScore DESC;
