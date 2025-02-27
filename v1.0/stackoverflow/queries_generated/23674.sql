WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM Posts p
    WHERE p.ViewCount > 1000
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT pc.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(u.Reputation) AS MaxReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    LEFT JOIN Comments pc ON pc.UserId = u.Id
    GROUP BY u.Id
),
RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentAction
    FROM PostHistory ph
    WHERE ph.CreationDate > NOW() - INTERVAL '30 days'
    AND ph.PostHistoryTypeId IN (10, 11, 12)
),
ClosedPostSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseActionCount,
        BOOLRANK() OVER (ORDER BY COUNT(ph.Id) DESC) AS CloseScore
    FROM Posts p
    LEFT JOIN RecentHistory ph ON p.Id = ph.PostId
    WHERE p.AcceptedAnswerId IS NULL
    AND p.ClosedDate IS NOT NULL
    GROUP BY p.Id
)

SELECT 
    u.DisplayName,
    up.PostCount,
    pr.CloseActionCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(rp.Title, 'No Rank') AS TopPostTitle,
    rp.ViewCount AS TopPostViewCount
FROM UserActivity up
LEFT JOIN Users u ON u.Id = up.UserId
LEFT JOIN ClosedPostSummary pr ON pr.PostId = u.Id
LEFT JOIN (SELECT * FROM RankedPosts WHERE Rank = 1) rp ON rp.PostId = ANY(SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM Badges 
    WHERE Class = 1
    GROUP BY UserId
) b ON b.UserId = u.Id
WHERE 
    up.PostCount > 0
    AND u.LastAccessDate > NOW() - INTERVAL '1 year'
ORDER BY 
    up.TotalBounty DESC, 
    BadgeCount DESC;
