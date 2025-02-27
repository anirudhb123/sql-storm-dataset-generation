
WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 1000
), PopularPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, P.AnswerCount, U.Reputation AS UserReputation
    FROM Posts P
    JOIN UserReputation U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) AND P.Score > 0
), PostTags AS (
    SELECT P.Id AS PostId, value AS Tag
    FROM Posts P
    CROSS APPLY STRING_SPLIT(P.Tags, '><')
    WHERE P.PostTypeId = 1
), TagPopularity AS (
    SELECT Tag, COUNT(Pt.PostId) AS PostCount
    FROM PostTags Pt
    GROUP BY Tag
    HAVING COUNT(Pt.PostId) > 5
), PopularityScores AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, P.AnswerCount, 
           (P.ViewCount * 0.2 + P.Score * 0.7 + P.AnswerCount * 0.1) AS PopularityScore
    FROM PopularPosts P
    JOIN TagPopularity T ON P.Title LIKE '%' + T.Tag + '%'
), RankedPosts AS (
    SELECT Id, Title, ViewCount, Score, AnswerCount, PopularityScore,
           ROW_NUMBER() OVER (ORDER BY PopularityScore DESC) AS Rank
    FROM PopularityScores
)
SELECT R.Title, R.ViewCount, R.Score, R.AnswerCount, R.Rank
FROM RankedPosts R
WHERE R.Rank <= 10
ORDER BY R.Rank;
