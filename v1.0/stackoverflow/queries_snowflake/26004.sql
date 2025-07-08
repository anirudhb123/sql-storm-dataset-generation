
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        LISTAGG(DISTINCT u.DisplayName, ', ') WITHIN GROUP (ORDER BY u.DisplayName) AS TopPostOwners
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        LISTAGG(DISTINCT b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgScore,
    us.PostsCreated,
    us.TotalViews AS UserTotalViews,
    us.TotalAnswers,
    bs.BadgeCount,
    bs.BadgeNames
FROM 
    TagStats ts
JOIN 
    UserPostStats us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%' LIMIT 1)
LEFT JOIN 
    BadgeStats bs ON bs.UserId = us.UserId
ORDER BY 
    ts.PostCount DESC, ts.TotalViews DESC;
