WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.Reputation,
    up.UpVotesCount,
    up.DownVotesCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC NULLS LAST, 
    rp.Score DESC NULLS FIRST
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Including a section for possible closed posts for the user and status
UNION ALL

SELECT 
    up.UserId,
    up.Reputation,
    up.UpVotesCount,
    up.DownVotesCount,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score
FROM 
    UserReputation up
INNER JOIN 
    Posts p ON up.UserId = p.OwnerUserId
WHERE 
    p.PostTypeId = 1
    AND p.Id IN (SELECT DISTINCT ph.PostId FROM PostHistory ph WHERE ph.PostHistoryTypeId = 10)
ORDER BY 
    up.Reputation DESC NULLS LAST, 
    p.Score DESC NULLS FIRST
LIMIT 5;
