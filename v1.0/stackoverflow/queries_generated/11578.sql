-- Performance benchmarking query on StackOverflow schema

-- This query retrieves statistics about posts, users, and their interactions
-- It calculates the total number of posts, average score per post, 
-- average view count per post, total votes cast, and total badges awarded to users.

SELECT
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgPostScore,
    AVG(p.ViewCount) AS AvgViewCount,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM
    Posts p
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Badges b ON b.UserId = p.OwnerUserId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= '2021-01-01' -- Filtering posts created from the year 2021 onwards
    AND p.PostTypeId = 1 -- Considering only Questions

