WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), PopularTags AS (
    SELECT T.TagName, COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ','))
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
), UserActivity AS (
    SELECT U.Id AS UserId, U.DisplayName, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           AVG(P.Score) AS AvgScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), ActiveUsers AS (
    SELECT UA.UserId, UA.DisplayName, UA.QuestionCount, UA.AnswerCount, UA.AvgScore
    FROM UserActivity UA
    WHERE UA.QuestionCount > 5 OR UA.AnswerCount > 10
), UserTagPerformance AS (
    SELECT A.UserId, A.DisplayName, T.TagName, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS UserQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS UserAnswers
    FROM ActiveUsers A
    JOIN Posts P ON A.UserId = P.OwnerUserId
    JOIN Tags T ON T.Id = ANY(string_to_array(P.Tags, ','))
    GROUP BY A.UserId, A.DisplayName, T.TagName
)
SELECT UBD.UserId, UBD.DisplayName, PT.TagName, UBD.BadgeCount,
       UTP.UserQuestions, UTP.UserAnswers
FROM UserBadges UBD
JOIN UserTagPerformance UTP ON UBD.UserId = UTP.UserId
JOIN PopularTags PT ON UTP.TagName = PT.TagName
ORDER BY UBD.BadgeCount DESC, UTP.UserAnswers DESC;
