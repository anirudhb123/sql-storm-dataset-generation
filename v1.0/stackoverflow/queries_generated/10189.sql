-- Performance benchmarking query for StackOverflow schema

-- 1. Count the total number of users who have posted questions and answers
SELECT 
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts WHERE PostTypeId = 1) AS TotalQuestions,
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts WHERE PostTypeId = 2) AS TotalAnswers
;

-- 2. Average score of questions and answers
SELECT 
    AVG(CASE WHEN PostTypeId = 1 THEN Score END) AS AvgQuestionScore,
    AVG(CASE WHEN PostTypeId = 2 THEN Score END) AS AvgAnswerScore
FROM 
    Posts
;

-- 3. Total votes for questions and answers
SELECT 
    SUM(CASE WHEN PostTypeId = 1 THEN Score END) AS TotalQuestionVotes,
    SUM(CASE WHEN PostTypeId = 2 THEN Score END) AS TotalAnswerVotes
FROM 
    Posts
;

-- 4. Number of posts per user
SELECT 
    OwnerUserId, 
    COUNT(*) AS PostCount
FROM 
    Posts
GROUP BY 
    OwnerUserId
ORDER BY 
    PostCount DESC
LIMIT 10
;

-- 5. Distribution of post types
SELECT 
    PostTypeId, 
    COUNT(*) AS PostCount 
FROM 
    Posts 
GROUP BY 
    PostTypeId 
ORDER BY 
    PostCount DESC
;

-- 6. Average view count for each post type
SELECT 
    PostTypeId, 
    AVG(ViewCount) AS AvgViewCount
FROM 
    Posts
GROUP BY 
    PostTypeId
;

-- 7. Number of comments per post
SELECT 
    PostId, 
    COUNT(*) AS CommentCount
FROM 
    Comments
GROUP BY 
    PostId
ORDER BY 
    CommentCount DESC
LIMIT 10
;

-- 8. Number of badges earned by users
SELECT 
    UserId, 
    COUNT(*) AS BadgeCount
FROM 
    Badges
GROUP BY 
    UserId
ORDER BY 
    BadgeCount DESC
LIMIT 10
;

-- 9. Most recent edits to posts
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate,
    ph.UserDisplayName,
    ph.Comment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
ORDER BY 
    ph.CreationDate DESC
LIMIT 10
;

-- 10. Posts with the highest number of likes
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score AS TotalLikes
FROM 
    Posts p
WHERE 
    p.Score > 0
ORDER BY 
    TotalLikes DESC
LIMIT 10
;
