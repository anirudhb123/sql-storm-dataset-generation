WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS TotalAnswers,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.Id,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ra.LastEditDate,
    ra.CloseCount,
    ra.ReopenCount,
    ur.TotalBounties,
    ur.TotalUpvotes
FROM 
    RankedPosts rp
JOIN 
    RecentActivity ra ON rp.Id = ra.Id
LEFT OUTER JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    (ra.CloseCount > 0 OR ra.ReopenCount > 0)
    AND rp.rn <= 5
ORDER BY 
    rp.CreationDate DESC;
