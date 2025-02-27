WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(ROUND(AVG(u.Reputation), 2), 0) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT pl.RelatedPostId) AS TotalRelatedPosts
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        qs.TotalComments,
        qs.TotalRelatedPosts,
        ups.AvgReputation,
        ROW_NUMBER() OVER (ORDER BY ups.TotalPosts DESC, ups.AvgReputation DESC) AS UserRank
    FROM 
        UserPostStats ups
    LEFT JOIN 
        QuestionStats qs ON ups.UserId = qs.OwnerUserId
    WHERE 
        ups.TotalPosts > 0
)
SELECT 
    hu.UserId,
    hu.DisplayName,
    COALESCE(hu.TotalPosts, 0) AS TotalPosts,
    COALESCE(hu.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(hu.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(hq.TotalComments, 0) AS TotalComments,
    COALESCE(hq.TotalRelatedPosts, 0) AS TotalRelatedPosts,
    COALESCE(hu.AvgReputation, 0) AS AvgReputation,
    hu.UserRank
FROM 
    TopUsers hu
FULL OUTER JOIN 
    (SELECT DISTINCT u.Id AS UserId, u.DisplayName, 'No Posts' AS Status 
     FROM Users u 
     WHERE NOT EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id)) AS np ON hu.UserId = np.UserId
LEFT JOIN 
    (SELECT OwnerUserId AS UserId, SUM(TotalComments) AS TotalComments 
     FROM QuestionStats 
     GROUP BY OwnerUserId) AS hq ON hu.UserId = hq.UserId
WHERE 
    hu.UserRank <= 10 OR np.Status IS NOT NULL
ORDER BY 
    hu.UserRank;
