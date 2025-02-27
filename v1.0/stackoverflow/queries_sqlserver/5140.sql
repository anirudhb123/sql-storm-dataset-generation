
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT ba.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges ba ON u.Id = ba.UserId
    GROUP BY 
        u.Id, u.DisplayName
), TrendingTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.TotalPosts,
    ua.TotalComments,
    tt.TagName AS TrendingTag
FROM 
    UserActivity ua
JOIN 
    TrendingTags tt ON ua.TotalPosts > 0
ORDER BY 
    ua.TotalPosts DESC, ua.TotalUpvotes DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
