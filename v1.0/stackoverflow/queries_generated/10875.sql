-- Performance benchmarking query to analyze user activity on posts, including post details, user information, and vote counts

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count of downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.UserName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.UpVotes,
    u.DownVotes,
    COALESCE(ROUND((u.UpVotes::float / NULLIF(u.TotalPosts, 0)) * 100, 2), 0) AS UpvotePercentage  -- Upvote percentage of total posts
FROM 
    UserPostStats u
ORDER BY 
    u.TotalPosts DESC;  -- Order by total posts for benchmarking
