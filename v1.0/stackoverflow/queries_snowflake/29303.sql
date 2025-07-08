
WITH PostTags AS (
    SELECT P.Id AS PostId, 
           VALUE AS TagName
    FROM Posts P,
         TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(P.Tags, 2, LEN(P.Tags) - 2), '><'))) AS VALUE)
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
           RANK() OVER (ORDER BY QuestionCount DESC, TotalScore DESC) AS TagRank
    FROM TagStatistics
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
