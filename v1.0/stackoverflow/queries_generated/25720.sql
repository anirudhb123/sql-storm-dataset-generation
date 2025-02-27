WITH TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts 
    JOIN Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagPopularity
    WHERE PostCount > 0
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount
    FROM TopTags 
    WHERE TagRank <= 10  -- Top 10 tags
),
UserActivity AS (
    SELECT 
        U.DisplayName AS UserName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.DisplayName
),
ActiveUsers AS (
    SELECT 
        U.UserName,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.TotalViews,
        RANK() OVER (ORDER BY U.TotalPosts DESC) AS UserRank
    FROM UserActivity U
    WHERE U.TotalPosts > 0
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    U.UserName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalViews
FROM PopularTags T
JOIN ActiveUsers U ON U.TotalPosts > 0
ORDER BY T.PostCount DESC, U.TotalPosts DESC;
