WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 years'
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS Comments
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts rp ON ph.PostId = rp.PostId
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.UserId, ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.PositiveScorePosts,
    us.NegativeScorePosts,
    us.BadgeCount,
    COALESCE(SUM(rp.Score), 0) AS TotalPostScore,
    uph.HistoryCount,
    SUBSTRING(uph.Comments FROM 1 FOR 600) AS SampleComments,
    COUNT(DISTINCT CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId 
        END) AS CloseCount,
    COUNT(DISTINCT CASE 
        WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId 
        END) AS ReopenCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    UserPostHistory uph ON us.UserId = uph.UserId
LEFT JOIN 
    PostHistory ph ON us.UserId = ph.UserId
GROUP BY 
    us.UserId, us.DisplayName, uph.HistoryCount
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
    AND us.BadgeCount > 0
ORDER BY 
    TotalPostScore DESC, us.DisplayName
LIMIT 50;
