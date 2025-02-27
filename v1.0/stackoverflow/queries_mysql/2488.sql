
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner_user_id := p.OwnerUserId,
        COALESCE(SUM(CASE WHEN vb.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vb.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId,
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(CASE WHEN vb.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AvgUpVotes, 
        AVG(COALESCE(CASE WHEN vb.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS AvgDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    up.UserId,
    up.Reputation,
    up.PostCount,
    rp.UpVotes,
    rp.DownVotes,
    @reputation_rank := @reputation_rank + 1 AS ReputationRank
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId,
    (SELECT @reputation_rank := 0) AS rank_vars
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, up.Reputation DESC
LIMIT 10;
