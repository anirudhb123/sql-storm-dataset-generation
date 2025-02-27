
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
        u.LastAccessDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH
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
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    RecentUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId AND p.PostTypeId = 1
OUTER APPLY (
    SELECT 
        value AS TagName
    FROM 
        STRING_SPLIT(p.Tags, '<>') 
) t
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.Id
GROUP BY 
    ru.DisplayName, ru.Reputation, ru.Id
HAVING 
    COUNT(DISTINCT rp.Id) > 5 OR SUM(rp.Score) > 50
ORDER BY 
    TotalScore DESC, UserCategory;
