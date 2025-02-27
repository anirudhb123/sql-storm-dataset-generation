WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostSummary AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts
    GROUP BY OwnerUserId
),
ClosedPostReasons AS (
    SELECT PostId, 
           MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS CloseDate,
           MAX(CASE WHEN PostHistoryTypeId = 10 THEN Comment END) AS CloseReason
    FROM PostHistory
    WHERE PostHistoryTypeId IN (10, 11)
    GROUP BY PostId
)

SELECT ur.DisplayName,
       ur.Reputation,
       ps.TotalPosts,
       ps.TotalQuestions,
       ps.TotalAnswers,
       COALESCE(cpr.CloseDate, 'No Closure') AS ClosureDate,
       COALESCE(cpr.CloseReason, 'N/A') AS ClosureReason
FROM UserReputation ur
LEFT JOIN PostSummary ps ON ur.Id = ps.OwnerUserId
LEFT JOIN ClosedPostReasons cpr ON ps.OwnerUserId = cpr.PostId
WHERE ur.Reputation > 1000
  AND (ps.TotalPosts > 5 OR ps.TotalQuestions > 2)
ORDER BY ur.Rank, ps.TotalPosts DESC;
