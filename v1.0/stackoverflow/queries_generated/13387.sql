-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves details about posts, along with user and badge information,
-- as well as the count of associated comments and votes, to assess performance
-- bottlenecks in retrieval and join operations.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    u.CreationDate AS AuthorCreationDate,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(COUNT(v.Id), 0) AS VoteCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created this year
GROUP BY 
    p.Id, u.Id, b.Id
ORDER BY 
    p.Score DESC, p.CreationDate DESC; -- Sorting by score and creation date for relevance
