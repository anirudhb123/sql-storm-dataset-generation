
WITH UserReputation AS (
    SELECT Id, Reputation, LastAccessDate,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, 
           ISNULL(PL.RelatedPostId, -1) AS RelatedPostId,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    OUTER APPLY (SELECT value AS TagName FROM STRING_SPLIT(P.Tags, ',')) T
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, PL.RelatedPostId
    HAVING COUNT(DISTINCT T.TagName) > 2
),
TopUsers AS (
    SELECT Id, Reputation
    FROM UserReputation
    WHERE Reputation > 1000 AND LastAccessDate > CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
),
PostAnalytics AS (
    SELECT TP.Title, TP.ViewCount, TP.Score,
           CASE WHEN U.Id IS NOT NULL THEN 'Active User' ELSE 'Inactive User' END AS UserStatus,
           TP.Tags
    FROM TopPosts TP
    LEFT JOIN TopUsers U ON TP.RelatedPostId = U.Id
),
FinalResults AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY Score DESC) AS ScoreQuartile,
           COUNT(*) OVER () AS TotalPosts
    FROM PostAnalytics
)
SELECT *,
       CASE WHEN ScoreQuartile = 1 THEN 'Top Performer'
            WHEN ScoreQuartile = 2 THEN 'High Performer'
            WHEN ScoreQuartile = 3 THEN 'Medium Performer'
            WHEN ScoreQuartile = 4 THEN 'Low Performer'
            ELSE 'Bottom Performer' END AS PerformanceCategory
FROM FinalResults
WHERE Score > 10 AND UserStatus = 'Active User'
ORDER BY ViewCount DESC;
