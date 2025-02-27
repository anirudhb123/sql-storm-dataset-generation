
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
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS RecentPostRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := 0) AS r
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR 
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
    LIMIT 5
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
LIMIT 10;
