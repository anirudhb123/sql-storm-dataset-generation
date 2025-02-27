
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    u.DisplayName,
    u.Reputation,
    ur.TotalBounties,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount - ps.UpVotes + ps.DownVotes AS InteractionScore,
    CASE 
        WHEN ps.CommentCount > 20 THEN 'Very Active'
        WHEN ps.CommentCount BETWEEN 10 AND 20 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    PostStatistics ps ON rp.Id = ps.PostId
WHERE 
    rp.rn = 1
    AND ur.Reputation > (
        SELECT AVG(Reputation) FROM UserReputation
    )
ORDER BY 
    InteractionScore DESC
LIMIT 50;
