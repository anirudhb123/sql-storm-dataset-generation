-- Performance benchmarking query to retrieve user activity, post details, and associated tags
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT p.AnswerCount) AS TotalAnswers,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.UserId = u.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_ids ON TRUE
LEFT JOIN 
    Tags t ON t.Id = tag_ids
WHERE 
    u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
