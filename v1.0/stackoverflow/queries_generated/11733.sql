-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves a summary of posts alongside user information,
-- and the total votes on each post to evaluate the performance
-- of commonly accessed data in the database.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.Score AS PostScore,
    COALESCE(v.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(v.DownVotesCount, 0) AS TotalDownVotes,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    t.TagName AS PostTag
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
LEFT JOIN 
    PostsTags pt ON p.Id = pt.PostId -- Assuming PostsTags is the table linking Posts and Tags
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Focus on posts from the last year
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100; -- Limit to the most recent 100 posts
