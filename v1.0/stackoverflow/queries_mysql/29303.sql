
WITH PostTags AS (
    SELECT P.Id AS PostId, 
           SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM Posts P
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE P.PostTypeId = 1  
),
TagStatistics AS (
    SELECT PT.TagName,
           COUNT(DISTINCT PT.PostId) AS QuestionCount,
           COUNT(DISTINCT C.Id) AS CommentCount,
           SUM(P.Score) AS TotalScore,
           AVG(U.Reputation) AS AvgUserReputation,
           COUNT(DISTINCT B.Id) AS BadgeCount
    FROM PostTags PT
    LEFT JOIN Posts P ON PT.PostId = P.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY PT.TagName
),
RankedTags AS (
    SELECT TagName,
           QuestionCount,
           CommentCount,
           TotalScore,
           AvgUserReputation,
           BadgeCount,
           @rank := @rank + 1 AS TagRank
    FROM TagStatistics, (SELECT @rank := 0) r
    ORDER BY QuestionCount DESC, TotalScore DESC
)
SELECT R.TagName,
       R.QuestionCount,
       R.CommentCount,
       R.TotalScore,
       R.AvgUserReputation,
       R.BadgeCount
FROM RankedTags R
WHERE R.TagRank <= 10
ORDER BY R.TagRank, R.TotalScore DESC;
