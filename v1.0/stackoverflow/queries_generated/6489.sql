WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COALESCE(SUM(pl.RelatedPostId IS NOT NULL), 0) AS TotalLinks,
        AVG(DATEDIFF('second', p.CreationDate, COALESCE(p.ClosedDate, NOW()))) AS AvgTimeToClose
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        u.Id
),
TopContributors AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        Upvotes, 
        Downvotes, 
        TotalLinks, 
        AvgTimeToClose,
        RANK() OVER (ORDER BY TotalPosts DESC) as PostRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    Upvotes,
    Downvotes,
    TotalLinks,
    ROUND(AvgTimeToClose / 3600, 2) AS AvgTimeToCloseInHours,
    CASE 
        WHEN TotalPosts > 50 THEN 'Expert'
        WHEN TotalPosts BETWEEN 20 AND 50 THEN 'Enthusiast'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    TopContributors
WHERE 
    PostRank <= 10
ORDER BY 
    Upvotes DESC;
