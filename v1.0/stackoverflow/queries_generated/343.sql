WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        us.TotalScore,
        us.PostCount
    FROM 
        UserScores us
    JOIN 
        Users u ON us.UserId = u.Id
    WHERE 
        us.TotalScore > 500
)
SELECT 
    tp.DisplayName,
    tp.TotalScore,
    tp.PostCount,
    rp.Title,
    rp.Score AS PostScore,
    rp.CommentCount
FROM 
    TopUsers tp
JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE 
    rp.OwnerRank <= 3
ORDER BY 
    tp.TotalScore DESC, rp.Score DESC;
