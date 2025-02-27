
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
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
    ISNULL(th.Tags, 'No Tags') AS Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    (SELECT 
        p.Id,
        STRING_AGG(t.TagName, ', ') AS Tags
     FROM 
        Posts p
     JOIN 
        STRING_SPLIT(p.Tags, ',') AS TagArray ON 1=1
     JOIN 
        Tags t ON t.TagName = TagArray.value
     GROUP BY 
        p.Id) th ON rp.PostId = th.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CommentCount DESC,
    ur.Reputation DESC;
