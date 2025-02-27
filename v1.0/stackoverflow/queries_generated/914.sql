WITH UserReputation AS (
    SELECT Id, Reputation, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TagStatistics AS (
    SELECT Tags.TagName, 
           COUNT(Posts.Id) AS PostCount, 
           SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = Posts.Id
    GROUP BY Tags.TagName
),
ClosedPosts AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           PH.CreationDate, 
           C.Name AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    JOIN CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
)
SELECT U.DisplayName, 
       U.Reputation, 
       TR.TagName, 
       TR.PostCount, 
       TR.TotalViews, 
       CP.Title AS ClosedPostTitle, 
       CP.CloseReason, 
       CP.CreationDate AS ClosedDate
FROM Users U
JOIN UserReputation UR ON U.Id = UR.Id AND UR.ReputationRank <= 10
LEFT JOIN TagStatistics TR ON U.Id = TR.TagName::int
LEFT JOIN ClosedPosts CP ON U.Id = CP.PostId
WHERE U.Reputation IS NOT NULL
ORDER BY U.Reputation DESC, TR.TotalViews DESC
LIMIT 50;

