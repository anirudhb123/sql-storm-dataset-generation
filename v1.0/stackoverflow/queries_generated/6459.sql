SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostTime,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) t ON TRUE
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
