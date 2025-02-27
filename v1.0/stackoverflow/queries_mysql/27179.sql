
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName SEPARATOR ', ') AS Users,
        GROUP_CONCAT(DISTINCT CASE WHEN B.Class = 1 THEN B.Name END ORDER BY B.Name SEPARATOR ', ') AS GoldBadges,
        GROUP_CONCAT(DISTINCT CASE WHEN B.Class = 2 THEN B.Name END ORDER BY B.Name SEPARATOR ', ') AS SilverBadges,
        GROUP_CONCAT(DISTINCT CASE WHEN B.Class = 3 THEN B.Name END ORDER BY B.Name SEPARATOR ', ') AS BronzeBadges
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        Users,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews,
        RANK() OVER (ORDER BY AverageScore DESC) AS RankByScore
    FROM 
        TagStatistics
),
BenchmarkResults AS (
    SELECT 
        *,
        CASE 
            WHEN RankByViews <= 5 THEN 'Top Viewed'
            ELSE 'Other'
        END AS ViewCategory,
        CASE 
            WHEN RankByScore <= 5 THEN 'Top Scored'
            ELSE 'Other'
        END AS ScoreCategory
    FROM 
        TopTags
)

SELECT 
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    Users,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    ViewCategory,
    ScoreCategory
FROM 
    BenchmarkResults
WHERE 
    ViewCategory = 'Top Viewed' OR ScoreCategory = 'Top Scored'
ORDER BY 
    TotalViews DESC, AverageScore DESC;
