WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn,
        COALESCE(NULLIF(LAG(p.LastEditDate) OVER (ORDER BY p.CreationDate), p.LastEditDate), p.CreationDate) AS PrevEditDate,
        COUNT(c.Id) FILTER (WHERE c.Id IS NOT NULL) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    GROUP BY 
        u.Id
),
PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        b.Name AS BadgeName,
        bh.UserId,
        b.Date AS AwardedDate
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId 
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 52
    LEFT JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    ur.AvgReputation,
    COALESCE(pb.BadgeName, 'No Badge') AS BadgeName,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN rp.PrevEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN 
    (SELECT PostId, ARRAY_AGG(BadgeName) AS Badges 
     FROM PostsWithBadges 
     GROUP BY PostId) pb ON pb.PostId = rp.PostId
WHERE 
    rp.rn = 1
AND 
    (rp.ViewCount > 500 OR ur.AvgReputation >= 1000)
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;
