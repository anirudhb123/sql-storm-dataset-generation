WITH RecursiveBadges AS (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount,
        MIN(Date) AS FirstBadgeDate
    FROM Badges
    GROUP BY UserId
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only questions
),
FilteredPostHistory AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryTypeName
    FROM PostHistory ph
    LEFT JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent changes
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT rp.PostId) AS QuestionCount,
        SUM(COALESCE(phh.PostHistoryTypeId IS NOT NULL, 0)) AS RecentEdits
    FROM Users u
    LEFT JOIN RecursiveBadges rb ON u.Id = rb.UserId
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerDisplayName
    LEFT JOIN FilteredPostHistory phh ON u.Id = phh.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        QuestionCount,
        RecentEdits,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC, QuestionCount DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.QuestionCount,
    tu.RecentEdits,
    CASE 
        WHEN tu.RecentEdits > 10 THEN 'Highly Active'
        WHEN tu.RecentEdits BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    pht.Name AS MostRecentPostHistoryTypeName
FROM TopUsers tu
LEFT JOIN PostHistory ph ON tu.UserId = ph.UserId 
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE tu.UserRank <= 10 -- Top 10 users
ORDER BY tu.UserRank;
