WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
),
PostHistories AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(ph.HistoryCount, 0) AS EditHistoryCount,
    CASE 
        WHEN ur.Reputation >= 1000 THEN 'Experienced'
        WHEN ur.Reputation IS NULL THEN 'No Reputation'
        ELSE 'Novice' 
    END AS UserExperienceLevel
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId = ur.UserId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
WHERE 
    rp.OwnerPostRank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
