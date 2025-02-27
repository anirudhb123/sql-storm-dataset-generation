WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
EnhancedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        MAX(u.Reputation) AS MaxReputation
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY u.Id, u.DisplayName
),
UserRanks AS (
    SELECT 
        UserId, 
        DisplayName,
        DENSE_RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank,
        DENSE_RANK() OVER (ORDER BY MaxReputation DESC) AS ReputationRank
    FROM EnhancedUserStats
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalBounty,
    up.BadgeCount,
    up.TotalQuestions,
    ur.BountyRank,
    ur.ReputationRank,
    iron.Id AS PostId,
    iron.Title,
    iron.CreationDate,
    iron.Score,
    iron.ViewCount,
    phs.HistoryCount,
    phs.LastModifiedDate
FROM EnhancedUserStats up
JOIN UserRanks ur ON up.UserId = ur.UserId
INNER JOIN RankedPosts iron ON up.UserId = iron.OwnerUserId AND iron.Rank <= 5 -- Top 5 questions by score per user
LEFT JOIN PostHistorySummary phs ON iron.Id = phs.PostId
WHERE 
    (up.TotalBounty > 0 OR up.BadgeCount > 0) -- Users with at least one bounty or badge
    AND ur.BountyRank < 10 -- Focusing on top 10 in bounties
    AND (phs.HistoryCount > 1 OR phs.LastModifiedDate IS NOT NULL)
ORDER BY up.TotalBounty DESC, ur.ReputationRank ASC;
