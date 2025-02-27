
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ur.DisplayName,
        ur.TotalReputation,
        ur.BadgeCount,
        COALESCE(COUNT(v.Id), 0) AS VoteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, ur.DisplayName, ur.TotalReputation, ur.BadgeCount
),
PostHistoryWithReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR ', ') AS HistoryTypes,
        GROUP_CONCAT(DISTINCT cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS CHAR)
    WHERE 
        ph.CreationDate >= CURDATE() - INTERVAL 6 MONTH
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.DisplayName AS OwnerDisplayName,
    rp.TotalReputation,
    rp.BadgeCount,
    rp.VoteCount,
    phwr.HistoryTypes,
    phwr.CloseReasons
FROM 
    RecentPosts rp
LEFT JOIN 
    PostHistoryWithReasons phwr ON rp.PostId = phwr.PostId
ORDER BY 
    rp.CreationDate DESC
LIMIT 50 OFFSET 0;
