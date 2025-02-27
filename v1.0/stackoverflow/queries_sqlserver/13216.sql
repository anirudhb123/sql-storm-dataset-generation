
WITH PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        COUNT(DISTINCT Id) AS TotalAnswers,
        COUNT(DISTINCT Id) AS TotalQuestions
    FROM 
        Posts
),
UserStatistics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
),
CommentStatistics AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM 
        Comments
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    ps.TotalPosts,
    ps.TotalUsers,
    ps.TotalAnswers,
    ps.TotalQuestions,
    us.TotalUsers AS UniqueUsers,
    us.AvgReputation,
    cs.TotalComments,
    cs.AvgCommentScore,
    rp.Id AS RecentPostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.OwnerDisplayName AS RecentPostOwner
FROM 
    PostStatistics ps,
    UserStatistics us,
    CommentStatistics cs,
    (SELECT TOP 10 Id, Title, CreationDate, OwnerDisplayName 
     FROM RecentPosts 
     ORDER BY CreationDate DESC) rp
GROUP BY 
    ps.TotalPosts,
    ps.TotalUsers,
    ps.TotalAnswers,
    ps.TotalQuestions,
    us.TotalUsers,
    us.AvgReputation,
    cs.TotalComments,
    cs.AvgCommentScore,
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName;
