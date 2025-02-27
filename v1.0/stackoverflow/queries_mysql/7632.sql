
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
    COALESCE(SUM(CASE WHEN ph.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalHistoryEntries,
    AVG(u.Reputation) AS AverageReputation,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT TRIM(tag) AS tag FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS tag
    FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) t) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag.tag = t.TagName
WHERE 
    u.CreationDate < '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, AverageReputation DESC
LIMIT 100;
