
WITH TagCounts AS (
    SELECT STRING_AGG(value, '') AS TagName,
           COUNT(*) AS PostCount
    FROM (
        SELECT value
        FROM Posts
        CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    ) AS TagsSplit
    WHERE PostTypeId = 1 
    GROUP BY value
),
TopTags AS (
    SELECT TagName, PostCount
    FROM TagCounts
    ORDER BY PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
           ROW_NUMBER() OVER (PARTITION BY T.TagName ORDER BY UA.TotalVotes DESC) AS Rank
    FROM TopTags T
    JOIN UserActivity UA ON UA.UserId IN (
        SELECT DISTINCT U.Id
        FROM Posts P
        JOIN Users U ON P.OwnerUserId = U.Id
        WHERE P.Tags LIKE '%' + T.TagName + '%'
    )
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
