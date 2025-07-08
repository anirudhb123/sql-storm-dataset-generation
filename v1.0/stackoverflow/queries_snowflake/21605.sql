
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        LISTAGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(year, -1, '2024-10-01')
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11, 12)  
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.BadgeNames, 'None') AS BadgeNames,
    r.PostId,
    r.Title,
    r.Score,
    r.CreationDate,
    p.HistoryCount,
    p.LastEditDate
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId AND r.UserRank = 1  
LEFT JOIN 
    PostHistoryAggregates p ON r.PostId = p.PostId
WHERE 
    u.Reputation > 100 AND  
    u.CreationDate < DATEADD(year, -1, '2024-10-01')  
ORDER BY 
    u.Reputation DESC, r.Score DESC
LIMIT 100  
OFFSET 0;
