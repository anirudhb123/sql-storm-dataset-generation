WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        SUM(p.Score) as TotalScore,
        COUNT(DISTINCT p.Id) as TotalPosts
    FROM 
        Users u 
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    u.DisplayName,
    tp.TotalScore,
    tp.TotalPosts,
    rp.Title,
    rp.Score,
    pv.UpVotes,
    pv.DownVotes
FROM 
    TopUsers tp
JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
WHERE 
    rp.Rank <= 3
ORDER BY 
    tp.TotalScore DESC, rp.Score DESC;
