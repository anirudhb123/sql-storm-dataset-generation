
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
), RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
), CloseReasons AS (
    SELECT 
        Ph.PostId,
        GROUP_CONCAT(Cr.Name SEPARATOR ', ') AS CloseReasonNames
    FROM PostHistory Ph
    JOIN CloseReasonTypes Cr ON CAST(Ph.Comment AS UNSIGNED) = Cr.Id
    WHERE Ph.PostHistoryTypeId = 10  
    GROUP BY Ph.PostId
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM Badges b
    GROUP BY b.UserId
), PostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.ReputationLevel,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pb.MaxBadgeClass, 0) AS MaxBadgeClass,
        p.PostId,
        p.Title,
        p.Score,
        cr.CloseReasonNames
    FROM UserReputation ur
    JOIN Users u ON ur.UserId = u.Id
    LEFT JOIN UserBadges pb ON u.Id = pb.UserId
    LEFT JOIN RankedPosts p ON u.Id = p.OwnerUserId
    LEFT JOIN CloseReasons cr ON p.PostId = cr.PostId
)
SELECT 
    ps.DisplayName,
    ps.ReputationLevel,
    ps.BadgeCount,
    ps.MaxBadgeClass,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(COALESCE(ps.Score, 0)) AS TotalScore,
    GROUP_CONCAT(ps.CloseReasonNames SEPARATOR '; ') AS AllCloseReasons
FROM PostSummary ps
GROUP BY 
    ps.DisplayName, 
    ps.ReputationLevel, 
    ps.BadgeCount, 
    ps.MaxBadgeClass
HAVING 
    COUNT(ps.PostId) > 0 AND 
    (SUM(COALESCE(ps.Score, 0)) > 10 OR ps.BadgeCount > 2)
ORDER BY 
    TotalScore DESC, 
    ps.DisplayName ASC
LIMIT 10 OFFSET 5;
