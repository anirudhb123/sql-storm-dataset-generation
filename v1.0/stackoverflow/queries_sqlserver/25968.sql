
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
),

BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        b.BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        BadgeCounts b ON u.Id = b.UserId
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalScore,
    ts.AvgViews,
    ts.Contributors,
    ur.DisplayName AS TopContributor,
    ur.Reputation,
    ur.BadgeCount
FROM 
    TagStats ts
JOIN 
    UserReputation ur ON ts.Contributors LIKE '%' + ur.DisplayName + '%'
ORDER BY 
    ts.PostCount DESC, ts.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
