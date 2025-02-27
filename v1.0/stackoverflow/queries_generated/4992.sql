WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP)
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ClosedDate,
        h.CreatedDate,
        CASE 
            WHEN h.UserId IS NULL THEN 'Closed by Vote'
            ELSE (SELECT UserDisplayName FROM Users WHERE Id = h.UserId)
        END AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory h ON p.Id = h.PostId
    WHERE 
        h.PostHistoryTypeId = 10 
        AND h.CreationDate >= DATEADD(MONTH, -6, CURRENT_TIMESTAMP)
)
SELECT 
    u.DisplayName AS UserName,
    ua.PostCount,
    ua.TotalBounties,
    ua.AvgBounty,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    cp.PostId AS ClosedPostId,
    cp.Title AS ClosedPostTitle,
    cp.ClosedBy,
    cp.ClosedDate
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.ScoreRank = 1
LEFT JOIN 
    ClosedPosts cp ON ua.UserId = cp.ClosedBy
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.TotalBounties DESC, ua.PostCount DESC;
