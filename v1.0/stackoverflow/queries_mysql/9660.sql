
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
    AVG(p.Score) AS AveragePostScore,
    MIN(p.CreationDate) AS FirstPostDate,
    MAX(p.CreationDate) AS LatestPostDate,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS PostTypes,
    GROUP_CONCAT(DISTINCT tag.TagName SEPARATOR ', ') AS UsedTags
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes vote ON p.Id = vote.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
     FROM 
     (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) tag ON TRUE
WHERE 
    u.CreationDate >= '2023-10-01 12:34:56'
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalUpVotes DESC, AveragePostScore DESC;
