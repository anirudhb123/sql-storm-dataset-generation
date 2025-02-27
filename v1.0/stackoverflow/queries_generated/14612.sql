-- Performance Benchmarking Query

-- This query retrieves the total number of posts, users, comments, and votes to evaluate
-- the complexity and performance of aggregate functions across related tables.

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM PostHistory) AS TotalPostHistory,
    (SELECT COUNT(*) FROM PostLinks) AS TotalPostLinks

-- A more complex benchmark query that joins multiple tables

-- This query aggregates the number of answers and total votes for each user
-- while joining with posts to measure the performance of join operations.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalAnswers,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes, -- Assuming VoteTypeId = 2 is upvote
    SUM(v.VoteTypeId = 3) AS TotalDownVotes -- Assuming VoteTypeId = 3 is downvote
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- PostTypeId = 2 for Answers
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalAnswers DESC
LIMIT 100; -- Limit to top 100 users by number of answers
