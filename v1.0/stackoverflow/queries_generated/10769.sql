-- Performance Benchmarking Query for the StackOverflow Schema

-- This query measures the performance across multiple joined tables
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes, -- UpMod
    SUM(v.VoteTypeId = 3) AS DownVotes, -- DownMod
    p.CreationDate,
    p.LastActivityDate,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tag ON true
LEFT JOIN 
    Tags t ON tag = t.TagName
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC;
