-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves user statistics, post counts and average scores for posts made by users along with the most recent activity.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    COUNT(P.Id) AS TotalPosts,
    COUNT(C.Id) AS TotalComments,
    AVG(P.Score) AS AveragePostScore,
    MAX(P.LastActivityDate) AS MostRecentPostActivity
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC;

-- The above query scans through the Users, Posts, and Comments tables to gather information, which can be used to benchmark performance relative to user engagement and activity levels.
