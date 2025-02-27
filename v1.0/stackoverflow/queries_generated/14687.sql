-- Performance Benchmarking Query

-- This query will retrieve statistics related to posts, their votes, and the users who created them
-- It will join multiple tables to measure performance on complex queries involving aggregations and joins.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS Downvotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'BountyStart' THEN v.BountyAmount ELSE 0 END), 0) AS TotalBounty,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Adjust the date filter as needed
GROUP BY 
    p.Id, u.Id
ORDER BY 
    VoteCount DESC, p.CreationDate DESC;

-- This query will give insight into which posts are most engaged with through votes
-- and the popularity of their authors, serving as a useful performance benchmark for the database.
