
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TagName FROM (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
          FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
          WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) as t) AS t ON TRUE
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedPosts
    FROM 
        Posts p 
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
ActivitySummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        COALESCE(cps.ClosedPosts, 0) AS ClosedPosts,
        ua.Tags
    FROM 
        UserActivity ua
    LEFT JOIN 
        ClosedPostStats cps ON ua.UserId = cps.OwnerUserId
)
SELECT 
    asu.UserId,
    asu.DisplayName,
    asu.TotalPosts,
    asu.TotalQuestions,
    asu.TotalAnswers,
    asu.TotalUpvotes,
    asu.TotalDownvotes,
    asu.ClosedPosts,
    CASE 
        WHEN asu.TotalPosts > 100 THEN 'Active Contributor'
        WHEN asu.TotalPosts > 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM 
    ActivitySummary asu
ORDER BY 
    asu.TotalUpvotes DESC, 
    asu.TotalPosts DESC 
LIMIT 20;
