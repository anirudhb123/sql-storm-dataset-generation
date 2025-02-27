
WITH RECURSIVE UserPostDetails AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

RecentPostEdits AS (
    SELECT
        ph.UserId,
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.UserId, ph.PostId
),

EditedPostCount AS (
    SELECT 
        rpd.UserId,
        COUNT(rpd.PostId) AS EditCount
    FROM RecentPostEdits rpd
    GROUP BY rpd.UserId
),

UserMetrics AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.Reputation,
        up.PostCount,
        up.TotalScore,
        COALESCE(ec.EditCount, 0) AS TotalEdits
    FROM UserPostDetails up
    LEFT JOIN EditedPostCount ec ON up.UserId = ec.UserId
),

TopUsers AS (
    SELECT 
        um.*,
        @row_num := @row_num + 1 AS UserRank
    FROM UserMetrics um, (SELECT @row_num := 0) r
    ORDER BY um.Reputation DESC
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalEdits,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN COALESCE(ub.BadgeCount, 0) > 0 THEN 'Has Badges'
        ELSE 'No Badges' 
    END AS BadgeStatus
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
) ub ON tu.UserId = ub.UserId
WHERE tu.UserRank <= 10
ORDER BY tu.Reputation DESC;
