
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY P.Score DESC, P.ViewCount DESC) AS RankByPerformance
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 
        AND P.Score > 10 
        AND P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
AggregatedData AS (
    SELECT 
        U.Location,
        COUNT(RP.PostId) AS NumberOfQuestions,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.AnswerCount) AS TotalAnswers,
        SUM(RP.ViewCount) AS TotalViews
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerDisplayName = U.DisplayName
    GROUP BY 
        U.Location
),
PopularTags AS (
    SELECT 
        DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(RP.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        RankedPosts RP
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
         (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
         (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
         ORDER BY n) n
    ON
        CHAR_LENGTH(RP.Tags) - CHAR_LENGTH(REPLACE(RP.Tags, '><', '')) >= n.n - 1
    WHERE 
        RankByPerformance <= 5 
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
)
SELECT 
    AD.Location,
    AD.NumberOfQuestions,
    AD.AverageScore,
    AD.TotalAnswers,
    AD.TotalViews,
    TP.Tag,
    TP.TagCount
FROM 
    AggregatedData AD
JOIN 
    TagPopularity TP ON AD.Location = TP.Tag
ORDER BY 
    AD.NumberOfQuestions DESC, 
    AD.AverageScore DESC
LIMIT 10;
