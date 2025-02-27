WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostWithMostVotes AS (
    SELECT 
        pId, 
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        pId
    ORDER BY 
        VoteCount DESC 
)
SELECT 
    rp.PostId,
    rp.Title,
    u.Reputation,
    ur.BadgeCount,
    COALESCE(pm.VoteCount, 0) AS TotalVotes,
    (CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
     END) AS ReputationCategory,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE ',' + p.Tags + ',' LIKE '%,' + t.TagName + ',%') AS AssociatedTags
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserReputation ur ON ur.UserId = u.Id
LEFT JOIN 
    PostWithMostVotes pm ON pm.pId = rp.PostId
WHERE 
    (u.Location IS NOT NULL OR u.AboutMe IS NOT NULL) 
    AND (u.Views IS NULL OR u.Views > 100)
    AND rp.rn = 1
ORDER BY 
    TotalVotes DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

