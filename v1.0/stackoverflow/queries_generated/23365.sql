WITH UserReputation AS (
    SELECT Id, Reputation, DisplayName,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation IS NOT NULL
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS PostCount, 
           SUM(p.Score) AS TotalScore,
           AVG(VIEWCount) AS AvgViewCount,
           MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT ph.PostId, 
           p.Title,
           ph.CreationDate AS ModificationDate,
           p.Body,
           ph.UserDisplayName,
           ph.PostHistoryTypeId,
           CASE 
               WHEN ph.PostHistoryTypeId IN (10, 11) THEN 
                   (SELECT cr.Name 
                    FROM CloseReasonTypes cr 
                    WHERE cr.Id = CAST(ph.Comment AS INT)) 
               ELSE NULL 
           END AS CloseReason,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Version
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate > DATEADD(YEAR, -1, CURRENT_TIMESTAMP) 
)
SELECT u.DisplayName, 
       ur.Reputation, 
       ps.PostCount, 
       ps.TotalScore, 
       COALESCE(phd.Title, 'No Title') AS LastModifiedPostTitle,
       phd.CloseReason,
       COUNT(DISTINCT b.Id) AS BadgeCount,
       AVG(phd.AvgViewCount) AS OverallAvgViewCount
FROM UserReputation ur
LEFT JOIN PostStats ps ON ur.Id = ps.OwnerUserId
LEFT JOIN PostHistoryDetails phd ON ur.Id = (SELECT OwnerUserId FROM Posts WHERE Id = phd.PostId)
LEFT JOIN Badges b ON b.UserId = ur.Id
WHERE ur.Rank <= 10 -- Considering high reputation users
GROUP BY ur.DisplayName, ur.Reputation, ps.PostCount, ps.TotalScore, phd.Title, phd.CloseReason
ORDER BY ur.Reputation DESC, ps.TotalScore ASC;

