-- Performance benchmarking query for StackOverflow schema
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    MAX(v.CreationDate) AS LastVoteDate,
    u.DisplayName AS OwnerDisplayName,
    t.TagName
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose votes
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId -- Answers
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id = (SELECT MIN(tag.Id) FROM Tags tag WHERE tag.Id IN (SELECT unnest(string_to_array(p.Tags, '><'))::int)) LIMIT 1) -- One of the tags for simplicity
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC; -- Sort by creation date for the latest questions
