-- Performance Benchmarking SQL Query

-- 1. Analyze average score of questions grouped by tags
SELECT 
    Tags.TagName, 
    AVG(Posts.Score) AS AverageScore
FROM 
    Posts
JOIN 
    Tags ON Tags.Id = (SELECT UNNEST(string_to_array(Posts.Tags, '>'))::int[])
WHERE 
    Posts.PostTypeId = 1 -- Questions only
GROUP BY 
    Tags.TagName
ORDER BY 
    AverageScore DESC;

-- 2. Total number of posts and their average view count by post type
SELECT 
    PostTypes.Name AS PostType, 
    COUNT(Posts.Id) AS TotalPosts, 
    AVG(Posts.ViewCount) AS AverageViewCount
FROM 
    Posts
JOIN 
    PostTypes ON Posts.PostTypeId = PostTypes.Id
GROUP BY 
    PostTypes.Name
ORDER BY 
    TotalPosts DESC;

-- 3. User activity: Aggregate actions by each user and their reputation
SELECT 
    Users.DisplayName, 
    COUNT(Posts.Id) AS TotalPosts, 
    SUM(COALESCE(Votes.VoteTypeId IS NOT NULL, 0)) AS TotalVotes,
    AVG(Users.Reputation) AS AverageReputation
FROM 
    Users
LEFT JOIN 
    Posts ON Posts.OwnerUserId = Users.Id
LEFT JOIN 
    Votes ON Votes.UserId = Users.Id
GROUP BY 
    Users.DisplayName
ORDER BY 
    TotalPosts DESC;

-- 4. Benchmark: Time taken for each post edit over the history of posts
SELECT 
    PostHistory.PostId,
    COUNT(PostHistory.Id) AS EditCount,
    MIN(PostHistory.CreationDate) AS FirstEdit,
    MAX(PostHistory.CreationDate) AS LastEdit,
    EXTRACT(EPOCH FROM (MAX(PostHistory.CreationDate) - MIN(PostHistory.CreationDate))) AS EditDurationInSeconds
FROM 
    PostHistory
WHERE 
    PostHistory.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
GROUP BY 
    PostHistory.PostId
ORDER BY 
    EditCount DESC;

-- 5. Most common close reasons for questions
SELECT 
    CloseReasonTypes.Name AS CloseReason, 
    COUNT(PostHistory.Id) AS CloseCount
FROM 
    PostHistory
JOIN 
    CloseReasonTypes ON CloseReasonTypes.Id = PostHistory.Comment::int
WHERE 
    PostHistory.PostHistoryTypeId IN (10, 11) -- Post Closed or Post Reopened
GROUP BY 
    CloseReasonTypes.Name
ORDER BY 
    CloseCount DESC;
