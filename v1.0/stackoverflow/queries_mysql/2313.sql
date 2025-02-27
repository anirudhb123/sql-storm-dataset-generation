
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > NOW() - INTERVAL 1 MONTH
)
SELECT 
    ru.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    COALESCE(SUM(rp.Score), 0) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    CASE 
        WHEN ru.Reputation > 1000 THEN 'Experienced User'
        ELSE 'New User'
    END AS UserCategory,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed
FROM 
    RecentUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    (SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS TagName
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) t ON true
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.Id
GROUP BY 
    ru.DisplayName, ru.Reputation
HAVING 
    COUNT(DISTINCT rp.Id) > 5 OR SUM(rp.Score) > 50
ORDER BY 
    TotalScore DESC, UserCategory;
