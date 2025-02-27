WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > now() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Reputation) AS AvgReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 0 AND rp.PostRank <= 5 -- considering only top 5 recent posts with score > 0
    GROUP BY 
        rp.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.UserId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        COUNT(*) OVER (PARTITION BY p.Id) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    a.TotalPosts,
    a.TotalScore,
    a.AvgReputation,
    COALESCE(cp.CloseCount, 0) AS TotalClosedPosts,
    ub.BadgeNames
FROM 
    Users u
JOIN 
    AggregatedData a ON u.Id = a.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON cp.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    u.Reputation > 1000 -- Selecting users with high reputation
    AND NOT EXISTS (SELECT 1 FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 3) -- Users who haven't downvoted any posts
ORDER BY 
    a.TotalScore DESC,
    a.TotalPosts DESC
LIMIT 10;
