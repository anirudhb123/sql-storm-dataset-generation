WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS tag,
        COUNT(*) AS tag_count
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        tag
    HAVING 
        COUNT(*) > 5
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalViews,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    pt.tag AS PopularTag,
    ra.PostId,
    ra.Title AS RecentPostTitle,
    ra.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    PopularTags pt ON ua.TotalPosts > 10
LEFT JOIN 
    RecentActivity ra ON ua.UserId = ra.PostId
WHERE 
    ua.TotalViews > 100
ORDER BY 
    ua.TotalPosts DESC, ua.TotalViews DESC;
