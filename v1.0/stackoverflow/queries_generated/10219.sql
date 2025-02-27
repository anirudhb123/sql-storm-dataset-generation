-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END), 0) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.Id AS UserId,
        u.DisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    ORDER BY 
        p.Score DESC, p.CreationDate DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.AvgViews,
    ups.LastPostDate,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount
FROM 
    UserPostStats ups
LEFT JOIN 
    TopPosts tp ON ups.UserId = tp.UserId
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC;
