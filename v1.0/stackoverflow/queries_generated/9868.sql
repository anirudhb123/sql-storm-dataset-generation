SELECT 
    u.DisplayName AS User_Name,
    COUNT(DISTINCT p.Id) AS Total_Posts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Total_Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Total_Answers,
    AVG(u.Reputation) AS Avg_Reputation,
    SUM(b.Class = 1)::int AS Total_Gold_Badges,
    SUM(b.Class = 2)::int AS Total_Silver_Badges,
    SUM(b.Class = 3)::int AS Total_Bronze_Badges,
    MAX(p.CreationDate) AS Last_Post_Date,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Associated_Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true
LEFT JOIN 
    Tags t ON tag::text = t.TagName
WHERE 
    u.CreationDate > CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Total_Posts DESC, Avg_Reputation DESC
LIMIT 10;
