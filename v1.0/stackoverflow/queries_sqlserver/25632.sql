
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostsByUserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    OUTER APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) t 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 5
)

SELECT 
    ru.DisplayName AS TopUser,
    ru.Reputation,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.Tags
FROM 
    TopUsers ru
JOIN 
    RankedPosts tp ON ru.Id = tp.PostId
WHERE 
    tp.PostsByUserRank <= 3 
ORDER BY 
    ru.Reputation DESC, 
    tp.Score DESC;
