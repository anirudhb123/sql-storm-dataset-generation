WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.CreationDate > NOW() - INTERVAL '1 year') AS PostsInLastYear,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.CreationDate > NOW() - INTERVAL '1 year') AS VotesInLastYear
    FROM 
        Users u
    WHERE
        u.Reputation > 1000
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 years'
),
TopUserPosts AS (
    SELECT 
        ur.DisplayName,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score
    FROM 
        RankedPosts p
    JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
    WHERE 
        p.PostRank = 1
)
SELECT 
    t.DisplayName,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
    ARRAY_AGG(DISTINCT tg.TagName) AS Tags
FROM 
    TopUserPosts t
LEFT JOIN 
    Comments c ON c.PostId = t.PostId
LEFT JOIN 
    Posts p ON p.Id = t.PostId
LEFT JOIN 
    (SELECT 
         unnest(string_to_array(p.Tags, '><')) AS TagName, 
         p.Id
     FROM 
         Posts p
     WHERE 
         p.Tags IS NOT NULL) tg ON tg.Id = t.PostId
GROUP BY 
    t.DisplayName, t.Title, t.CreationDate, t.ViewCount, t.Score
HAVING 
    COUNT(DISTINCT c.Id) > 5
ORDER BY 
    t.Score DESC
LIMIT 10;
