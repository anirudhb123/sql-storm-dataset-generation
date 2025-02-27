
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounties,
        SUM(ISNULL(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory
    WHERE 
        CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalBounties,
    us.TotalBadgeClass,
    rp.Title,
    rp.Score,
    rp.RecentPostRank,
    ISNULL(phc.HistoryCount, 0) AS RecentHistoryCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    us.PostCount > 5
ORDER BY 
    us.TotalBounties DESC, us.PostCount DESC;
