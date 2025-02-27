WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        pt.Name AS PostType, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 9  -- BountyClose
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount, 
        MIN(ph.CreationDate) AS FirstEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName, 
    u.Reputation,
    ua.PostCount, 
    ua.TotalBounties,
    rp.Title,
    rp.CreationDate,
    phs.EditCount,
    phs.FirstEditDate
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
