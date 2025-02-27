-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the average response time for questions and the total votes received, 
-- along with the most recent post's details to analyze performance

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) AS ResponseTime, -- Response time in seconds
        COALESCE(v.Upvotes, 0) AS TotalUpvotes,
        COALESCE(v.Downvotes, 0) AS TotalDownvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers are connected to Questions
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
)

SELECT 
    AVG(ResponseTime) AS AverageResponseTime,
    SUM(TotalUpvotes) AS TotalVotes,
    MAX(ResponseTime) AS MaxResponseTime,
    MIN(ResponseTime) AS MinResponseTime,
    COUNT(PostId) AS TotalQuestions
FROM 
    PostMetrics;
