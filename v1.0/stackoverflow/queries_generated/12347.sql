-- Performance benchmarking query for Stack Overflow schema

-- This query measures the execution time for retrieving the number of posts, 
-- the average score of posts, and the count of users who voted on posts.

SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    COUNT(DISTINCT V.UserId) AS TotalUniqueVoters
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2020-01-01'  -- Filter for posts created in 2020 or later
AND 
    P.PostTypeId = 1;  -- Only consider questions

-- Results will provide insights into post engagement and voting activity.
