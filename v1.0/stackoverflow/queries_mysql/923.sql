
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
OwnerReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS RankedPostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopOwners AS (
    SELECT 
        UserId,
        Reputation,
        RankedPostCount,
        RANK() OVER (ORDER BY Reputation DESC, RankedPostCount DESC) AS OwnerRank
    FROM 
        OwnerReputation
)
SELECT 
    o.UserId, 
    o.Reputation, 
    o.RankedPostCount, 
    p.Title,
    COALESCE(GROUP_CONCAT(t.TagName SEPARATOR ', '), 'No Tags') AS Tags,
    COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
    COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
FROM 
    TopOwners o
JOIN 
    Posts p ON o.UserId = p.OwnerUserId
LEFT JOIN 
    Tags t ON FIND_IN_SET(t.TagName, p.Tags) > 0
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    o.OwnerRank <= 5
GROUP BY 
    o.UserId, o.Reputation, o.RankedPostCount, p.Title
ORDER BY 
    o.Reputation DESC, UpVotes DESC
LIMIT 10;
