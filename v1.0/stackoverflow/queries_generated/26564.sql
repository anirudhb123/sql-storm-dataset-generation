WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalWikis,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(STRING_AGG(DISTINCT p.Tags, ','), ',')) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
ActiveUsersWithTopTags AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalWikis,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        pt.TagName
    FROM 
        UserActivity ua
    JOIN 
        (SELECT uv.UserId, pt.TagName
         FROM UserActivity uv
         JOIN Posts p ON uv.UserId = p.OwnerUserId
         JOIN unnest(string_to_array(p.Tags, ',')) AS pt(TagName) ON pt.TagName IS NOT NULL
         GROUP BY uv.UserId, pt.TagName) AS pt ON ua.UserId = pt.UserId
    WHERE 
        ua.TotalPosts > 0
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalWikis,
    u.TotalUpvotes,
    u.TotalDownvotes,
    ARRAY_AGG(DISTINCT t.TagName) AS PopularTags
FROM 
    ActiveUsersWithTopTags u
JOIN 
    PopularTags t ON TRUE
GROUP BY 
    u.UserId
ORDER BY 
    u.TotalPosts DESC
LIMIT 10;
