
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
PostHistoryTags AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.tagName
    WHERE 
        ph.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 6 MONTH)
    GROUP BY 
        ph.PostId
)
SELECT 
    up.OwnerUserId,
    u.DisplayName AS UserDisplayName,
    up.TotalScore,
    up.PostCount,
    up.AvgViewCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    COALESCE(pht.Tags, 'No Tags') AS PostTags,
    CASE 
        WHEN pp.Score >= 0 THEN 'Non-negative Score'
        ELSE 'Negative Score'
    END AS ScoreCategory
FROM 
    TopUsers up
JOIN 
    RankedPosts pp ON up.OwnerUserId = pp.OwnerUserId
LEFT JOIN 
    PostHistoryTags pht ON pp.PostId = pht.PostId
JOIN 
    Users u ON u.Id = up.OwnerUserId
WHERE 
    pp.RN = 1 
    AND up.PostCount > 10
ORDER BY 
    up.TotalScore DESC, 
    pp.ViewCount DESC
LIMIT 50;
