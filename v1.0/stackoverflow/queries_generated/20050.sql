WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        ROUND(AVG(u.Reputation) OVER (PARTITION BY u.Id), 2) AS AvgReputation,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    us.AvgReputation,
    us.TotalBadges,
    us.TotalPosts,
    COALESCE(cp.CloseCount, 0) AS ClosureInteractions,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    Users up
JOIN 
    UserStatistics us ON up.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND rp.ViewCount = (SELECT MAX(ViewCount) FROM Posts WHERE OwnerUserId = up.Id)
WHERE 
    us.TotalPosts >= 5
    AND us.AvgReputation > (SELECT AVG(AvgReputation) FROM UserStatistics) 
ORDER BY 
    us.TotalBadges DESC, 
    us.AvgReputation DESC
FETCH FIRST 10 ROWS ONLY;

This SQL query evaluates and ranks users based on their posts while taking into account various metrics such as user reputation, badges earned, and interactions with closed posts. It incorporates Common Table Expressions (CTEs) for clarity, utilizes window functions for partitioning data, includes conditional expressions, handles potential NULL values gracefully, and demonstrates the use of complex predicates.
