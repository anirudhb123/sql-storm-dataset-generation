
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT r.PostId) AS QuestionCount,
        SUM(r.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserAggregates
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    CASE 
        WHEN tu.ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    COALESCE((SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ')
               FROM Posts p
               JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS TagName
                     FROM Posts p
                     JOIN (SELECT a.N + b.N * 10 AS n
                           FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
                           CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                           ) n
                     WHERE n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', ''))) n
               WHERE p.OwnerUserId = tu.UserId AND p.PostTypeId = 1), 'No Tags') AS TagsUsed
FROM 
    TopUsers tu
WHERE 
    tu.QuestionCount > 5
ORDER BY 
    tu.TotalScore DESC, tu.QuestionCount DESC;
