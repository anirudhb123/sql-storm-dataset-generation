WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS post_count
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN CloseReasonTypes ctr ON ctr.Id::text = ph.Comment
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    COUNT(*) AS TotalQuestions,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    us.Reputation,
    us.TotalBounty,
    us.BadgeCount,
    cp.CloseReasons,
    MAX(rp.rn) AS MaxRank
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
GROUP BY 
    up.DisplayName, us.Reputation, us.TotalBounty, us.BadgeCount, cp.CloseReasons
HAVING 
    COUNT(*) > 5 
ORDER BY 
    TotalScore DESC, TotalQuestions DESC;
