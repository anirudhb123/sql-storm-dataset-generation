
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END), 0) AS AvgViewCount
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId AS EditorUserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
), 
FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name SEPARATOR ', ') AS PostHistoryTypes,
        MAX(ph.HistoryDate) AS LastActionDate
    FROM 
        PostHistoryDetails ph
    INNER JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    GROUP BY 
        ph.PostId
) 
SELECT 
    u.DisplayName,
    u.Reputation,
    up.AvgViewCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(fph.PostHistoryTypes, 'No Actions') AS PostHistorySummary,
    fph.LastActionDate,
    CASE 
        WHEN rp.PostRank > 1 THEN 'Multiple Posts'
        ELSE 'Single Post'
    END AS PostMultiplicity
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation up ON u.Id = up.UserId
LEFT JOIN 
    FilteredPostHistory fph ON rp.PostId = fph.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (
        (rp.Title LIKE '%SQL%' OR rp.Title LIKE '%database%') 
        OR 
        fph.PostHistoryTypes IS NOT NULL
    )
ORDER BY 
    up.AvgViewCount DESC, rp.CreationDate DESC
LIMIT 100 OFFSET 0;
