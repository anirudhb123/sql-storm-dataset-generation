
SELECT 
    u.DisplayName AS User_Name,
    COUNT(DISTINCT p.Id) AS Total_Posts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Total_Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Total_Answers,
    AVG(u.Reputation) AS Avg_Reputation,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS Total_Gold_Badges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS Total_Silver_Badges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS Total_Bronze_Badges,
    MAX(p.CreationDate) AS Last_Post_Date,
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Associated_Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    LATERAL FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag
LEFT JOIN 
    Tags t ON tag.VALUE = t.TagName
WHERE 
    u.CreationDate > DATEADD(year, -1, CURRENT_DATE())
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Total_Posts DESC, Avg_Reputation DESC
LIMIT 10;
