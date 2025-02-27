WITH RecursiveBadges AS (
    SELECT U.Id, U.DisplayName, B.Name AS BadgeName, B.Class, B.Date,
           ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS RN
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
),
PostStats AS (
    SELECT P.OwnerUserId, 
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(P.Score) AS TotalScore,
           AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
LastActivity AS (
    SELECT P.OwnerUserId, 
           MAX(P.LastActivityDate) AS LastPostActivity
    FROM Posts P
    WHERE P.LastActivityDate IS NOT NULL
    GROUP BY P.OwnerUserId
)
SELECT U.DisplayName, 
       U.Reputation, 
       COALESCE(B.BadgeName, 'No Badge') AS Badge,
       PS.QuestionCount,
       PS.AnswerCount,
       PS.TotalScore,
       PS.AvgViewCount,
       LA.LastPostActivity,
       CASE 
           WHEN PS.QuestionCount > 10 THEN 'Active Contributor'
           WHEN PS.QuestionCount <= 10 AND PS.QuestionCount > 0 THEN 'Occasional Contributor'
           ELSE 'Lurker'
       END AS UserType,
       STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
FROM Users U
LEFT JOIN RecursiveBadges B ON U.Id = B.Id AND B.RN = 1
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN LastActivity LA ON U.Id = LA.OwnerUserId
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN LATERAL (
    SELECT DISTINCT SUBSTRING(Tags FROM '([^<,>]+)') AS TagName
    FROM unnest(string_to_array(P.Tags, ',')) AS T
) T ON true
WHERE U.Reputation > 100
GROUP BY U.DisplayName, U.Reputation, B.BadgeName, 
         PS.QuestionCount, PS.AnswerCount, PS.TotalScore, PS.AvgViewCount, LA.LastPostActivity
ORDER BY PS.TotalScore DESC, U.DisplayName;
