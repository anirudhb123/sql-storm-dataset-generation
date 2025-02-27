
WITH PostStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
),
CommentStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
),
UserStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalUsers
    FROM 
        Users
    GROUP BY 
        DATE_FORMAT(CreationDate, '%Y-%m-01')
)
SELECT 
    COALESCE(p.Month, c.Month, u.Month) AS Month,
    COALESCE(TotalPosts, 0) AS TotalPosts,
    COALESCE(TotalQuestions, 0) AS TotalQuestions,
    COALESCE(TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TotalComments, 0) AS TotalComments,
    COALESCE(TotalUsers, 0) AS TotalUsers
FROM 
    PostStats p
LEFT JOIN 
    CommentStats c ON p.Month = c.Month
LEFT JOIN 
    UserStats u ON COALESCE(p.Month, c.Month) = u.Month
ORDER BY 
    Month;
