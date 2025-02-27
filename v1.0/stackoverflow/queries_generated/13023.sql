-- Performance Benchmarking Query
-- This query retrieves the number of posts, comments, votes, and users,
-- along with the average votes per post and the average comments per post.

SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(votes_per_post) AS AvgVotesPerPost,
    AVG(comments_per_post) AS AvgCommentsPerPost
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
CROSS JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS votes_per_post 
     FROM 
        Votes 
     GROUP BY 
        PostId) AS post_votes ON p.Id = post_votes.PostId
CROSS JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS comments_per_post 
     FROM 
        Comments 
     GROUP BY 
        PostId) AS post_comments ON p.Id = post_comments.PostId;
