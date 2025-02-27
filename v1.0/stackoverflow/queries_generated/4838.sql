WITH UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(P.Score) AS TotalScore,
           COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY U.Id
),
ActiveUsers AS (
    SELECT UserId,
           DisplayName,
           QuestionCount,
           AnswerCount,
           TotalScore,
           CommentCount,
           RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserActivity
)
SELECT A.DisplayName,
       A.QuestionCount,
       A.AnswerCount,
       A.TotalScore,
       A.CommentCount,
       COALESCE(CASE WHEN A.QuestionRank = 1 THEN 'Top Questioner' ELSE NULL END, 
                  CASE WHEN A.ScoreRank = 1 THEN 'Top Contributor' END) AS Achievement
FROM ActiveUsers A
LEFT JOIN Badges B ON A.UserId = B.UserId
WHERE A.QuestionCount > 5 OR A.AnswerCount > 10
    AND B.Id IS NULL
ORDER BY A.TotalScore DESC, A.QuestionCount DESC
LIMIT 20;

-- Include the comments count from those posts contributed by users with a name like '%user%'
SELECT 
    U.DisplayName,
    COUNT(DISTINCT C.Id) AS TotalComments
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
JOIN Comments C ON P.Id = C.PostId
WHERE U.DisplayName ILIKE '%user%'
GROUP BY U.DisplayName
HAVING COUNT(DISTINCT C.Id) > 5
ORDER BY TotalComments DESC;
