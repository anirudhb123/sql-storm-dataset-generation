WITH RecursiveUsers AS (
    SELECT Id, Reputation, UpVotes, DownVotes, DisplayName, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS rn
    FROM Users
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users) -- Only above average reputation
), 
UserBadges AS (
    SELECT ub.UserId, COUNT(*) AS TotalBadges, 
           STRING_AGG(ub.Name, ', ') AS BadgeNames
    FROM Badges ub
    GROUP BY ub.UserId
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostHistory AS (
    SELECT u.Id AS UserId, 
           COUNT(ph.Id) AS EditCount, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 24 THEN ph.CreationDate END) AS LastEditDate,
           COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM Users u
    LEFT JOIN PostHistory ph ON ph.UserId = u.Id 
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edit types
    GROUP BY u.Id
)

SELECT u.Id AS UserId, 
       u.DisplayName, 
       u.Reputation, 
       COALESCE(ub.TotalBadges, 0) AS TotalBadges, 
       COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames, 
       COALESCE(ps.QuestionCount, 0) AS QuestionCount, 
       COALESCE(ps.TotalScore, 0) AS TotalScore,
       COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
       COALESCE(uph.EditCount, 0) AS EditCount, 
       COALESCE(uph.LastEditDate, 'Never') AS LastEditDate, 
       COALESCE(uph.UniquePostsEdited, 0) AS UniquePostsEdited
FROM RecursiveUsers u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN UserPostHistory uph ON u.Id = uph.UserId
WHERE u.Rn = 1 -- Only the most recent entry
AND (u.Reputation > 100 OR uph.EditCount > 5) -- Filter criteria
ORDER BY u.Reputation DESC, TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination

-- Edge Cases
-- Here, the query cleverly incorporates users who have either above-average reputation
-- or have a noteworthy number of edits while also pulling detailed stats on badges,
-- post performance while ensuring efficient aggregation with CTEs.
