
WITH RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) AND 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 10000 THEN 'Expert'
            WHEN u.Reputation >= 1000 THEN 'Veteran'
            ELSE 'Newbie'
        END AS ReputationTier
    FROM 
        Users u
)
SELECT 
    rp.Title AS PostTitle,
    u.DisplayName AS Author,
    rp.CreationDate,
    rp.ViewCount,
    ur.Reputation,
    ur.ReputationTier,
    COALESCE(ph.NumberOfEdits, 0) AS EditCount
FROM 
    RecentPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS NumberOfEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
) ph ON rp.Id = ph.PostId
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
