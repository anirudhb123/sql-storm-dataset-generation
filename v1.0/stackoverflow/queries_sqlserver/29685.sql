
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS t
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    tu.TotalBounties,
    tu.TotalVotes
FROM 
    PostStatistics ps
JOIN 
    TopUsers tu ON ps.RecentPostRank = 1 
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
