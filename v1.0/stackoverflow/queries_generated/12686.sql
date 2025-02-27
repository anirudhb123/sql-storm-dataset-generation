-- Performance benchmarking query for StackOverflow schema

-- This query retrieves posts with their associated users, comments, votes, and badges,
-- only for those posts that are questions (PostTypeId = 1) and have more than 5 answers.
-- It also joins on the Users, Comments, Votes, and Badges tables to get additional insights.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score AS PostScore,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(b.Name, ', ') AS BadgeNames
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Join to get answers
LEFT JOIN 
    Comments c ON c.PostId = p.Id -- Join to get comments
LEFT JOIN 
    Votes v ON v.PostId = p.Id -- Join to get votes
LEFT JOIN 
    Badges b ON b.UserId = u.Id -- Join to get badges
WHERE 
    p.PostTypeId = 1 -- considering only questions
GROUP BY 
    p.Id, u.Id
HAVING 
    COUNT(DISTINCT a.Id) > 5 -- Only include questions with more than 5 answers
ORDER BY 
    p.CreationDate DESC; -- Order results by post creation date
