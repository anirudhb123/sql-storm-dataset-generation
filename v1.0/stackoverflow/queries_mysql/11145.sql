
SELECT 
    ph.PostId,
    COUNT(ph.Id) AS HistoryCount,
    MAX(ph.CreationDate) AS LastModified,
    GROUP_CONCAT(DISTINCT p.Title ORDER BY p.Title SEPARATOR ', ') AS PostTitles,
    GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name SEPARATOR ', ') AS PostTypes,
    GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS ModifiedByUsers
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    ph.PostId
ORDER BY 
    HistoryCount DESC;
