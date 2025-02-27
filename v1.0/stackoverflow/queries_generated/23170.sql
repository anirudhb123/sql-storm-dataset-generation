WITH UserReputation AS (
    SELECT 
        Id,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PopularQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(*) AS TotalEdits
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId BETWEEN 4 AND 8
    GROUP BY ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.ReputationCategory,
    pq.Title AS MostPopularQuestion,
    pq.Score AS QuestionScore,
    bh.BadgeCount,
    bh.BadgeNames,
    COALESCE(phs.LastClosedDate, 'Never Closed') AS LastClosedDate,
    phs.TotalEdits,
    CASE 
        WHEN pq.Score IS NOT NULL AND pq.Rank = 1 THEN 'Top Performer'
        ELSE 'Regular User'
    END AS UserStatus
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN PopularQuestions pq ON u.Id = pq.OwnerUserId AND pq.Rank = 1
LEFT JOIN UserBadges bh ON u.Id = bh.UserId
LEFT JOIN PostHistoryStats phs ON u.Id = (SELECT OwnerUserId FROM Posts p WHERE p.Id = phs.PostId) 
WHERE u.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY ur.ReputationCategory DESC, bh.BadgeCount DESC NULLS LAST;
