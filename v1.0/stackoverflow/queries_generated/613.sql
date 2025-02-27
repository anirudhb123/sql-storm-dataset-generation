WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
)
SELECT 
    ts.PostId,
    ts.Title,
    ts.CreationDate,
    ts.Score,
    ts.ViewCount,
    ts.OwnerDisplayName,
    us.TotalPosts,
    us.TotalBounties
FROM 
    TopPosts ts
LEFT JOIN 
    UserStats us ON ts.OwnerDisplayName = us.UserId
WHERE 
    us.TotalPosts >= 5
ORDER BY 
    ts.Score DESC, ts.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS PostId,
    'Summary' AS Title,
    NULL AS CreationDate,
    COUNT(*) AS TotalTopPosts,
    SUM(ts.Score) AS TotalScore,
    NULL AS OwnerDisplayName,
    NULL AS TotalPosts,
    NULL AS TotalBounties
FROM 
    TopPosts ts;
