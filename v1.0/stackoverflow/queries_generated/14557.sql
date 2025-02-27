-- Performance Benchmarking Query to analyze user activity and post engagement

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    SUM(V.VoteTypeId = 2) AS TotalUpVotes,
    SUM(V.VoteTypeId = 3) AS TotalDownVotes,
    SUM(P.ViewCount) AS TotalViews,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation > 0  -- filter for users with positive reputation
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 100; -- limit to top 100 users by post count
