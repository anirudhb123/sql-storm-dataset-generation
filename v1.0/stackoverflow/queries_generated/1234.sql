WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.ViewCount) > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    pu.DisplayName,
    pu.TotalViews,
    rp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
JOIN 
    PopularUsers pu ON pu.UserId = rp.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, pu.TotalViews DESC;
