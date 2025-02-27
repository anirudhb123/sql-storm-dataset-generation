
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag 
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                      SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag 
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
UserRankings AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        PopularUsers
)

SELECT 
    ur.DisplayName,
    ur.PostCount,
    ur.TotalScore,
    COALESCE(rp.Tags, '') AS TopTags,
    rp.Score AS TopScore,
    rp.CreationDate
FROM 
    UserRankings ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.PostId
WHERE 
    ur.UserRank <= 5
ORDER BY 
    ur.TotalScore DESC, rp.Score DESC
LIMIT 10;
