
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        Wikis,
        TotalScore,
        @row_number := IF(@prev_score = TotalScore, @row_number, @row_number + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM UserStats, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY TotalScore DESC
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY T.TagName
),
TagStats AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        @tag_rank := IF(@prev_count = PostCount, @tag_rank, @tag_rank + 1) AS TagRank,
        @prev_count := PostCount
    FROM TopTags, (SELECT @tag_rank := 0, @prev_count := NULL) AS vars
    ORDER BY PostCount DESC
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.Wikis,
    T.TagName AS TopTag,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount
FROM TopUsers U
JOIN TagStats T ON T.TagRank = 1
WHERE U.ScoreRank <= 5
ORDER BY U.TotalScore DESC, U.DisplayName;
