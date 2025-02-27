
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalScore,
    up.TotalViews,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViewCount,
    COALESCE(ph.EditCount, 0) AS TotalEdits
FROM 
    UserStatistics up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
ORDER BY 
    up.TotalScore DESC, up.Reputation DESC;
