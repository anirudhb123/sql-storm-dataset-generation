
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentVotes AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    WHERE 
        CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    IFNULL(rv.TotalVotes, 0) AS TotalVotes,
    IFNULL(rv.UpVotes, 0) AS UpVotes,
    IFNULL(rv.DownVotes, 0) AS DownVotes
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
WHERE 
    (rp.rn = 1 OR rv.TotalVotes IS NOT NULL)
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 100;
