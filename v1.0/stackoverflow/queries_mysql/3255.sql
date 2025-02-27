
WITH RankedUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        @row_num := @row_num + 1 AS ReputationRank
    FROM 
        Users, (SELECT @row_num := 0) AS r
    WHERE 
        Reputation > 1000
    ORDER BY 
        Reputation DESC
),
LatestPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score,
        @post_rank := IF(@current_user = p.OwnerUserId, @post_rank + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @post_rank := 0, @current_user := NULL) AS rp
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
      AND p.Score > 0
    ORDER BY 
        p.OwnerUserId, p.LastActivityDate DESC
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    lp.Title,
    lp.CreationDate,
    pv.VoteCount,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN pv.UpVotes IS NULL THEN 'No Votes'
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive Impact'
        ELSE 'Negative Impact'
    END AS VoteImpact,
    @user_rank := @user_rank + 1 AS UserRank
FROM 
    RankedUsers u, (SELECT @user_rank := 0) AS ur
JOIN 
    LatestPosts lp ON u.Id = lp.OwnerUserId
LEFT JOIN 
    PostVotes pv ON lp.PostId = pv.PostId
WHERE 
    lp.PostRank = 1
ORDER BY 
    u.Reputation DESC, 
    lp.CreationDate DESC
LIMIT 10 OFFSET 0;
