
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    MAX(p.CreationDate) AS LastPostDate,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed,
    u.Reputation,
    u.CreationDate AS AccountCreationDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT DISTINCT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) TagName
     FROM 
        Posts p 
     INNER JOIN 
        (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) t ON p.Id = t.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    TotalPosts DESC, LastPostDate DESC
LIMIT 50;
