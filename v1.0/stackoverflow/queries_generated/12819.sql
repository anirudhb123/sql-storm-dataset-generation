-- Performance Benchmarking SQL Query

-- This query benchmarks the performance of fetching posts along with their relevant data
-- from the Stack Overflow schema. It includes joins between the Posts, Users, Tags, and Votes tables.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id IN (
        SELECT DISTINCT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int
    )
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- We're only interested in Questions
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting the results for benchmarking purposes
