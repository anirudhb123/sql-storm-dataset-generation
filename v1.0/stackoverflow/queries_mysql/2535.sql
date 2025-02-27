
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS tag,
        COUNT(*) AS tag_count
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
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
        @row := IF(@prev = p.OwnerUserId, @row + 1, 1) AS rn,
        @prev := p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @row := 0, @prev := NULL) r
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
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
