WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COALESCE(AVG(p.ViewCount), 0) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(DISTINCT ph.Id) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- closed, reopened, deleted, undeleted
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    us.UserId,
    us.BadgeCount,
    us.PositivePosts,
    us.NegativePosts,
    us.AvgViewCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    COALESCE(ph.ChangeCount, 0) AS ChangeCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistoryChanges ph ON rp.PostId = ph.PostId
WHERE 
    us.BadgeCount > 0
ORDER BY 
    us.PositivePosts DESC, us.NegativePosts ASC, us.AvgViewCount DESC
LIMIT 100;

