-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = p.Id) AS TotalVotes,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = p.Id) AS TotalComments,
    (SELECT string_agg(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

-- This query selects the latest 100 questions,
-- including the post details, owner information,
-- total votes, total comments, and associated tags.
