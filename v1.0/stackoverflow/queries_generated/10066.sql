-- Performance Benchmarking Query for Stack Overflow Schema

-- Query to measure the average number of votes and comments per post type
SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(AVG(vote_counts.VoteCount), 0) AS AvgVotes,
    COALESCE(AVG(comment_counts.CommentCount), 0) AS AvgComments
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) AS vote_counts ON vote_counts.PostId = p.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS comment_counts ON comment_counts.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Query to measure the average view count per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AvgViewCount DESC;

-- Query to benchmark average score for accepted answers
SELECT 
    COALESCE(AVG(a.Score), 0) AS AvgAcceptedAnswerScore,
    COUNT(a.Id) AS TotalAcceptedAnswers
FROM 
    Posts a
WHERE 
    a.PostTypeId = 2 AND a.AcceptedAnswerId IS NOT NULL;

-- Query to find the most recent post activity by post type
SELECT 
    pt.Name AS PostType,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    MostRecentActivity DESC;
