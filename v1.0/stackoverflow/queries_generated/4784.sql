WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 500
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    u.UserId,
    u.DisplayName,
    COUNT(tp.Id) AS TopPostCount,
    SUM(tp.Score) AS TopPostScore,
    COALESCE(cp.ClosedPostCount, 0) AS RecentClosedCount,
    STRING_AGG(DISTINCT tp.Title, ', ') AS TopPostTitles,
    COUNT(DISTINCT cp.PostId) AS UniqueClosedPosts
FROM 
    TopUsers u
JOIN 
    RankedPosts tp ON u.UserId = tp.OwnerUserId
LEFT JOIN (
    SELECT 
        cp.UserId,
        COUNT(cp.PostId) AS ClosedPostCount
    FROM 
        ClosedPosts cp
    JOIN 
        Posts p ON cp.PostId = p.Id
    GROUP BY 
        cp.UserId
) cp ON u.UserId = cp.UserId
WHERE 
    tp.PostRank <= 3
GROUP BY 
    u.UserId, u.DisplayName
ORDER BY 
    TopPostScore DESC
LIMIT 10;
