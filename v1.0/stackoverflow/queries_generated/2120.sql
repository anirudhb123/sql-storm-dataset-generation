WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        SUM(v.VoteTypeId = 2) OVER(PARTITION BY p.Id) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) OVER(PARTITION BY p.Id) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
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
    HAVING 
        SUM(p.Score) > 100
)
SELECT 
    u.DisplayName,
    COALESCE(rp.Title, 'No Posts') AS PostTitle,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    COALESCE(rp.Score, 0) AS PostScore,
    tu.TotalScore,
    tu.PostCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Activity'
        WHEN rp.Score > 50 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS ActivityStatus
FROM 
    TopUsers tu
FULL OUTER JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.TotalScore IS NOT NULL OR rp.Id IS NOT NULL
ORDER BY 
    tu.TotalScore DESC NULLS LAST, 
    rp.Score DESC NULLS LAST
LIMIT 100;
