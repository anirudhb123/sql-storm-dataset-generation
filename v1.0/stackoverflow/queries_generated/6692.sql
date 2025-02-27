WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId = 1
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(p.Id) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
FinalRanks AS (
    SELECT 
        t.DisplayName,
        t.PostCount,
        t.TotalScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY t.TotalScore DESC, t.PostCount DESC) AS OverallRank
    FROM TopUsers t
    LEFT JOIN UserBadges ub ON t.UserId = ub.UserId
)
SELECT 
    fr.DisplayName,
    fr.PostCount,
    fr.TotalScore,
    fr.BadgeCount,
    fr.OverallRank,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM FinalRanks fr
LEFT JOIN RankedPosts rp ON fr.UserId = rp.OwnerUserId AND rp.PostRank = 1
ORDER BY fr.OverallRank
LIMIT 10;
