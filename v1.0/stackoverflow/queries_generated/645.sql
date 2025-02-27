WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
    WHERE PostCount > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedPostCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.OwnerUserId
),
FinalStats AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.PostCount,
        tu.TotalScore,
        tu.AvgViewCount,
        ub.Badges,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount
    FROM TopUsers tu
    LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
    LEFT JOIN ClosedPosts cp ON tu.UserId = cp.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AvgViewCount,
    Badges,
    ClosedPostCount,
    CASE 
        WHEN TotalScore > 1000 THEN 'High Scorer'
        WHEN TotalScore BETWEEN 500 AND 1000 THEN 'Mid Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM FinalStats
WHERE ScoreRank <= 10
ORDER BY TotalScore DESC;
