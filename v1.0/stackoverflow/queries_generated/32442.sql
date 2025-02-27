WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationTier
    FROM Users
),
PostAggregate AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(Score) AS AvgScore,
        MAX(CreationDate) AS LastPostDate
    FROM Posts
    GROUP BY OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        DATEDIFF(MINUTE, p.CreationDate, ph.CreationDate) AS TimeToClose,
        ph.UserDisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.ReputationTier,
    pa.TotalPosts,
    pa.Questions,
    pa.Answers,
    pa.AvgScore,
    pa.LastPostDate,
    cb.PostId,
    cb.Title,
    cb.TimeToClose,
    cb.ClosedBy,
    ub.BadgeCount,
    ub.BadgeNames
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PostAggregate pa ON u.Id = pa.OwnerUserId
LEFT JOIN ClosedPosts cb ON u.Id = cb.ClosedBy
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE (ur.ReputationTier = 'High' OR ur.ReputationTier IS NULL)
  AND (pa.TotalPosts > 0 OR cb.PostId IS NOT NULL)
ORDER BY u.DisplayName, cb.CloseDate DESC;
