
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        AnswerCount,
        QuestionCount,
        @UserRank := IFNULL(@UserRank, 0) + 1 AS UserRank
    FROM UserStats, (SELECT @UserRank := 0) AS R
    ORDER BY TotalScore DESC, Reputation DESC
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Tags T
    JOIN Posts P ON FIND_IN_SET(T.TagName, P.Tags) > 0
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 50
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        @TagRank := IFNULL(@TagRank, 0) + 1 AS TagRank
    FROM PopularTags, (SELECT @TagRank := 0) AS R
    ORDER BY PostCount DESC
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.TotalScore AS Score,
    U.QuestionCount,
    U.AnswerCount,
    T.TagName AS MostPopularTag,
    T.PostCount AS TagPostCount
FROM TopUsers U
JOIN TopTags T ON U.QuestionCount > 0
WHERE U.UserRank <= 10 AND T.TagRank = 1
ORDER BY U.TotalScore DESC, U.Reputation DESC;
