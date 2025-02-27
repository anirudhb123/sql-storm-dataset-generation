WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastEarned
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(month, -6, GETDATE()) -- Badges earned in the last 6 months
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
) 
SELECT 
    u.DisplayName,
    u.Reputation,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    rb.BadgeCount,
    ISNULL(phd.HistoryTypes, 'No Changes') AS HistoryTypes,
    COALESCE(DATEDIFF(day, phd.LastChangeDate, GETDATE()), -1) AS DaysSinceLastChange
FROM 
    Users u
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId AND r.rn = 1 -- Latest post for each user
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    PostHistoryDetails phd ON r.PostId = phd.PostId
WHERE 
    u.Reputation > 1000 -- Users with more than 1000 reputation
ORDER BY 
    u.Reputation DESC, 
    r.CreationDate DESC
OPTION (MAXDOP 4);
