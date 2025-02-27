
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND (p.PostTypeId = 1 OR p.PostTypeId = 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    ur.DisplayName,
    ur.ReputationCategory,
    rp.CommentCount,
    COALESCE(th.Tags, 'No Tags') AS Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    (SELECT 
        p.Id,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
     FROM 
        Posts p
     JOIN 
        (SELECT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS TagName
         FROM Posts p
         CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                      UNION ALL SELECT 9 UNION ALL SELECT 10) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS TagArray ON TRUE
     JOIN 
        Tags t ON t.TagName = TagArray.TagName
     GROUP BY 
        p.Id) th ON rp.PostId = th.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CommentCount DESC,
    ur.Reputation DESC;
