
WITH UserReputation AS (
    SELECT Id, Reputation, LastAccessDate,
           @row_number := @row_number + 1 AS ReputationRank
    FROM Users, (SELECT @row_number := 0) AS rn
    ORDER BY Reputation DESC
),
TopPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, 
           COALESCE(PL.RelatedPostId, -1) AS RelatedPostId,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    JOIN (
        SELECT P.Id AS PostId, SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1) AS TagName
        FROM Posts P
        JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1
    ) T ON P.Id = T.PostId
    WHERE P.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, PL.RelatedPostId
    HAVING COUNT(DISTINCT T.TagName) > 2
),
TopUsers AS (
    SELECT Id, Reputation
    FROM UserReputation
    WHERE Reputation > 1000 AND LastAccessDate > DATE_SUB('2024-10-01 12:34:56', INTERVAL 30 DAY)
),
PostAnalytics AS (
    SELECT TP.Title, TP.ViewCount, TP.Score,
           CASE WHEN U.Id IS NOT NULL THEN 'Active User' ELSE 'Inactive User' END AS UserStatus,
           TP.Tags
    FROM TopPosts TP
    LEFT JOIN TopUsers U ON TP.RelatedPostId = U.Id
),
FinalResults AS (
    SELECT TP.Title, TP.ViewCount, TP.Score,
           UserStatus, Tags,
           NTILE(5) OVER (ORDER BY Score DESC) AS ScoreQuartile,
           COUNT(*) OVER () AS TotalPosts
    FROM PostAnalytics TP
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
