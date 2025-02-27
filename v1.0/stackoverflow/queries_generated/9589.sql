WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(COALESCE(b.Class, 0) * CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) AS TotalBadgePoints,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(b.Class, 0) * CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalBadgePoints, 
        TotalPosts, 
        TotalViews
    FROM 
        RankedUsers
    WHERE 
        Rank <= 10
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName, 
    tu.TotalBadgePoints, 
    tu.TotalPosts, 
    tu.TotalViews, 
    pt.TagName
FROM 
    TopUsers tu
CROSS JOIN 
    PopularTags pt
ORDER BY 
    tu.TotalBadgePoints DESC, 
    pt.PostCount DESC;
