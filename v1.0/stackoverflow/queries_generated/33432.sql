WITH RECURSIVE UserPosts AS (
    SELECT u.Id AS UserId, 
           p.Id AS PostId, 
           p.CreationDate, 
           p.Score, 
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS Rn
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT ph.PostId,
           p.Title,
           ph.PostHistoryTypeId,
           COUNT(*) AS HistoryCount,
           MIN(ph.CreationDate) AS FirstModifiedDate,
           MAX(ph.CreationDate) AS LastModifiedDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Only considering close, reopen, delete, and undelete actions
    GROUP BY ph.PostId, p.Title, ph.PostHistoryTypeId
),
ScoreSummary AS (
    SELECT UserId, 
           SUM(Score) AS TotalScore, 
           COUNT(DISTINCT PostId) AS PostCount,
           AVG(Score) AS AverageScore
    FROM UserPosts
    WHERE Rn <= 100 -- Limit to most recent 100 posts per user
    GROUP BY UserId
),
HighScorers AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           us.TotalScore, 
           us.PostCount, 
           us.AverageScore
    FROM Users u
    JOIN ScoreSummary us ON u.Id = us.UserId
    WHERE us.TotalScore > 1000
)
SELECT hs.UserId, 
       hs.DisplayName, 
       COALESCE(ph.HistoryCount, 0) AS ModificationCount, 
       hs.TotalScore,
       hs.PostCount,
       (SELECT COUNT(*) FROM Comments c WHERE c.UserId = hs.UserId) AS CommentCount,
       STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM HighScorers hs
LEFT JOIN PostHistoryAnalysis ph ON hs.UserId IN (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 11, 12, 13))
) 
LEFT JOIN Posts p ON p.OwnerUserId = hs.UserId
LEFT JOIN Tags t ON POSITION(t.TagName IN p.Tags) > 0 -- Checking if any tags exist in the post
GROUP BY hs.UserId, hs.DisplayName, hs.TotalScore, hs.PostCount, ph.HistoryCount
ORDER BY hs.TotalScore DESC, ModificationCount DESC;
