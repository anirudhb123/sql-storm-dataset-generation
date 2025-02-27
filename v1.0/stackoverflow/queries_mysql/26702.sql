
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        @row_number := @row_number + 1 AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN (SELECT @row_number := 0) AS R
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagUsageCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 0
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        CONCAT('/posts/', P.Id) AS PostUrl
    FROM Posts P
    WHERE P.PostTypeId IN (1, 2)
    ORDER BY P.Score DESC, P.ViewCount DESC
    LIMIT 10
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.QuestionCount,
    RU.AnswerCount,
    PT.TagName,
    PT.TagUsageCount,
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.PostUrl
FROM RankedUsers RU
CROSS JOIN PopularTags PT
CROSS JOIN TopPosts TP
WHERE RU.UserRank <= 100
ORDER BY RU.Reputation DESC, PT.TagUsageCount DESC, TP.Score DESC;
