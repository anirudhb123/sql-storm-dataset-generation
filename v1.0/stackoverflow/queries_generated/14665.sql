-- Performance Benchmarking Query

-- Get the total number of posts, along with average score, answer count, and comment count per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    AVG(p.CommentCount) AS AverageCommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Get the count of users and their average reputation, grouped by creation date year
SELECT 
    EXTRACT(YEAR FROM u.CreationDate) AS Year,
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
GROUP BY 
    Year
ORDER BY 
    Year;

-- Get the total number of votes and average vote type entries per post
SELECT 
    p.Title,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.VoteTypeId) AS AverageVoteType
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalVotes DESC;

-- Get badge distribution per user to analyze user engagement
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    TotalBadges DESC;

-- Analyze comment distribution over time, monthly
SELECT 
    DATE_TRUNC('month', c.CreationDate) AS Month,
    COUNT(c.Id) AS TotalComments
FROM 
    Comments c
GROUP BY 
    Month
ORDER BY 
    Month;
