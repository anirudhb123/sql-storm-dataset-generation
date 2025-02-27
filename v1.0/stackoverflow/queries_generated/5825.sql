WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT ph.Id) AS TotalPostHistory
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions, 
        TotalComments, 
        TotalUpvotes, 
        TotalDownvotes, 
        TotalBadges, 
        TotalPostHistory,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalUpvotes DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    au.DisplayName,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.TotalComments,
    au.TotalUpvotes,
    au.TotalDownvotes,
    au.TotalBadges,
    au.TotalPostHistory,
    CASE 
        WHEN au.TotalBadges > 5 THEN 'Highly Active User' 
        WHEN au.TotalPosts > 20 THEN 'Active Contributor' 
        ELSE 'Newcomer' 
    END AS UserCategory
FROM 
    ActiveUsers au
WHERE 
    au.ActivityRank <= 50
ORDER BY 
    au.ActivityRank;
