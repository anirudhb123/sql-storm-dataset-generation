
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId,
        COALESCE(v.UpVotes, 0) as UpVotes,
        COALESCE(v.DownVotes, 0) as DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    us.DisplayName,
    us.TotalScore,
    us.PostCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.UpVotes > rp.DownVotes
    AND us.TotalScore > 100
ORDER BY 
    rp.Score DESC
LIMIT 50;
