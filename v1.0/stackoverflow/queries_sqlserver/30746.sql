
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate,
        STRING_AGG(ph.Comment, '; ') AS ChangeComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalBadges,
    up.TotalBounties,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ph.ChangeCount,
    ph.LastChangeDate,
    ph.ChangeComments
FROM 
    UserActivity up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryAnalysis ph ON rp.Id = ph.PostId
WHERE 
    up.TotalPosts > 10
    AND rp.ScoreRank <= 5
ORDER BY 
    up.TotalPosts DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
