
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1)) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10 -- Adjust this as necessary for the maximum number of tags
    ) AS numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),

TagStatistics AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        ProcessedTags pt
    LEFT JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        Tag
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(p.ViewCount, 0)) > 1000 
)

SELECT 
    ts.Tag,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalAnswers,
    ur.DisplayName AS TopUser,
    ur.TotalBadgeClass,
    ur.TotalPosts,
    ur.TotalViews AS UserTotalViews
FROM 
    TagStatistics ts
JOIN 
    UserReputation ur ON ts.PostCount = (
        SELECT MAX(PostCount)
        FROM TagStatistics
    )
ORDER BY 
    ts.TotalViews DESC, ts.TotalAnswers DESC
LIMIT 10;
