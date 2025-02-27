WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score AS PostScore,
    rp.CommentCount,
    rp.TotalBounty
FROM 
    TopUsers pu
JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1 
    AND (rp.Score > 50 OR rp.CommentCount > 10)
ORDER BY 
    pu.TotalScore DESC, 
    rp.ViewCount DESC
LIMIT 10
UNION
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS PostScore,
    NULL AS CommentCount,
    NULL AS TotalBounty
FROM 
    Users u
WHERE 
    u.Reputation < 100
    AND u.LastAccessDate < NOW() - INTERVAL '6 months'
ORDER BY 
    u.Reputation ASC
LIMIT 5;
