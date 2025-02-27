-- Performance benchmarking query for the Stack Overflow schema

-- Retrieve post statistics with user details, including the number of votes, comments, and badges
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,  -- Count of UpVotes
    COUNT(c.Id) AS CommentsCount,  -- Count of Comments
    COUNT(b.Id) AS BadgesCount  -- Count of Badges owned by the user
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.PostTypeId = 1  -- Only consider Questions
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit results to the latest 100 questions
