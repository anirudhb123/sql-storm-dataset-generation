WITH ProcessedTags AS (
    SELECT 
        PostId,
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
    FROM Posts
    WHERE PostTypeId = 1 -- Only considering questions
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId = 1 -- Only questions
    GROUP BY U.Id
    ORDER BY TotalScore DESC
    LIMIT 10
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(P.Score) AS TotalScore
    FROM ProcessedTags PT
    JOIN Posts P ON PT.PostId = P.Id
    JOIN Tags T ON PT.Tag = T.TagName
    GROUP BY T.TagName
    ORDER BY TotalScore DESC
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        AvgViewCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM TagStatistics
    WHERE QuestionCount > 5 -- Only considering tags used in more than 5 questions
)
SELECT 
    U.DisplayName AS TopUser,
    T.TagName AS PopularTag,
    T.QuestionCount,
    T.AvgViewCount,
    T.TotalScore
FROM TopUsers U
JOIN TopTags T ON U.QuestionCount > 0
ORDER BY T.TotalScore DESC, U.TotalScore DESC;
