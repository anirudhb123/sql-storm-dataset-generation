
WITH TagCounts AS (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
           COUNT(*) AS PostCount
    FROM Posts
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT TagName, PostCount
    FROM TagCounts
    ORDER BY PostCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
           COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided,
           COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsMade,
           COALESCE(SUM(V.VoteAmount), 0) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS VoteAmount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
FinalStats AS (
    SELECT T.TagName,
           UA.UserId,
           UA.DisplayName,
           UA.QuestionsAsked,
           UA.AnswersProvided,
           UA.CommentsMade,
           UA.TotalVotes,
           @rank := IF(@prevTag = T.TagName, @rank + 1, 1) AS Rank,
           @prevTag := T.TagName
    FROM TopTags T
    JOIN UserActivity UA ON UA.UserId IN (
        SELECT DISTINCT U.Id
        FROM Posts P
        JOIN Users U ON P.OwnerUserId = U.Id
        WHERE P.Tags LIKE CONCAT('%.', T.TagName, '.%')
    ),
    (SELECT @rank := 0, @prevTag := '') r
)
SELECT TagName,
       UserId,
       DisplayName,
       QuestionsAsked,
       AnswersProvided,
       CommentsMade,
       TotalVotes
FROM FinalStats
WHERE Rank <= 5
ORDER BY TagName, TotalVotes DESC;
