
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTagUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(T.Tag) AS TagCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) AS Tag
          FROM Posts P
          JOIN (SELECT a.N + b.N * 10 AS n 
                FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a 
                CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
          WHERE n.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) + 1) T
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(T.Tag) > 10
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        RANK() OVER (ORDER BY P.Score DESC, P.AnswerCount DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBounty,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    T.TagCount,
    PP.Title,
    PP.Score,
    PP.AnswerCount
FROM UserStats US
LEFT JOIN TopTagUsers T ON US.UserId = T.UserId
LEFT JOIN PopularPosts PP ON PP.PostId IN (
    SELECT R.PostId
    FROM PopularPosts R
    WHERE R.PostRank <= 10
)
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, PP.Score DESC
LIMIT 10;
