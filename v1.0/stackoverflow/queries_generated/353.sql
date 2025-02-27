WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01'
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerName,
        COALESCE(ph.Comment, 'No edits yet.') AS RecentEditComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN LATERAL (
        SELECT 
            ph.Comment 
        FROM 
            PostHistory ph 
        WHERE 
            ph.PostId = rp.PostId 
        ORDER BY 
            ph.CreationDate DESC 
        LIMIT 1
    ) ph ON true
    WHERE 
        rp.PostRank <= 5
),
PostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AvgScore
    FROM 
        Posts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    rp.OwnerName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AvgScore
FROM 
    RecentPosts rp
JOIN 
    PostStats ps ON rp.OwnerUserId = ps.OwnerUserId
ORDER BY 
    ps.TotalViews DESC, 
    rp.CreationDate DESC
LIMIT 50
OFFSET 10;
