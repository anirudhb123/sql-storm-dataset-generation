-- Performance Benchmarking Query

-- This query aims to evaluate the database performance by accessing multiple related tables 
-- and performing aggregations and counts.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(b.Reputation) AS AvgUserReputation,
    SUM(b.Rank) AS TotalBadges,  -- Assuming there is a Rank field that can be summed
    MAX(ph.CreationDate) AS LastEditDate
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
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1  -- Filtering only 'Questions'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
