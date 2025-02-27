WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(AVG(P.Score), 0) AS AvgPostScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.Score) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT * 
    FROM UserPostStats 
    WHERE TotalPosts > 0
    ORDER BY TotalPosts DESC
    LIMIT 10
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM Tags T
    LEFT JOIN Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))::int[]
    GROUP BY T.TagName
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AvgPostScore,
    PT.TagName AS PopularTag,
    PT.PostCount
FROM TopUsers TU
LEFT JOIN PopularTags PT ON TU.UserId = (
    SELECT U.Id
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.Tags LIKE '%' || PT.TagName || '%'
    LIMIT 1
)
ORDER BY TU.UserRank, PT.PostCount DESC;
