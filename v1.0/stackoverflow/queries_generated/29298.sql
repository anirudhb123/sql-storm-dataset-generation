WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(trim(both '<>' FROM P.Tags), '::int'))
    GROUP BY 
        T.TagName
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        RANK() OVER (ORDER BY UA.UpvotedPosts DESC) AS RankByUpvotes
    FROM 
        UserActivity UA
    WHERE
        UA.TotalPosts > 0
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.LastPostDate,
    TU.DisplayName AS TopUser,
    TU.TotalPosts AS TopUserPosts,
    TU.TotalQuestions AS TopUserQuestions,
    TU.TotalAnswers AS TopUserAnswers
FROM 
    TagStatistics TS
JOIN 
    TopUsers TU ON TS.PostCount = (
        SELECT MAX(PostCount) 
        FROM TagStatistics 
        WHERE PostCount <= TS.PostCount
    )
ORDER BY 
    TS.PostCount DESC, TU.RankByUpvotes ASC
LIMIT 10;
