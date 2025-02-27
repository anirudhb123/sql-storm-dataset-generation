
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), EffectiveUserStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.PostCount,
        UPS.TotalScore,
        UPS.AvgViewCount,
        UPS.TotalAnswers,
        UPS.QuestionCount,
        UPS.AnswerCount,
        @row_num := @row_num + 1 AS Rank
    FROM UserPostStats UPS, (SELECT @row_num := 0) r
    WHERE UPS.PostCount > 0
    ORDER BY UPS.TotalScore DESC
)

SELECT 
    EUS.DisplayName,
    EUS.PostCount,
    EUS.TotalScore,
    EUS.AvgViewCount,
    EUS.TotalAnswers,
    EUS.QuestionCount,
    EUS.AnswerCount,
    (SELECT GROUP_CONCAT(T.TagName SEPARATOR ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
     WHERE P.OwnerUserId = EUS.UserId) AS PopularTags
FROM EffectiveUserStats EUS
WHERE EUS.Rank <= 10
ORDER BY EUS.TotalScore DESC;
