WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ru.Username,
    ru.TotalScore,
    ru.PostCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount
FROM 
    TopUsers ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.OwnerUserId
WHERE 
    rp.rn <= 5
ORDER BY 
    ru.TotalScore DESC, ru.PostCount DESC, rp.Score DESC;
