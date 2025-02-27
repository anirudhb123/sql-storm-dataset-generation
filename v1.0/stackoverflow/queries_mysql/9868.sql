
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
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Associated_Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT tag FROM (
        SELECT SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) AS tags
        FROM Posts p
    ) AS temp JOIN (
        SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(temp.tags, '><', numbers.n), '><', -1)) AS tag
        FROM (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10
        ) numbers INNER JOIN temp ON CHAR_LENGTH(temp.tags)
        -CHAR_LENGTH(REPLACE(temp.tags, '><', '')) >= numbers.n-1
    ) AS tags ON 1=1) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag = t.TagName
WHERE 
    u.CreationDate > DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Total_Posts DESC, Avg_Reputation DESC
LIMIT 10;
