
WITH RECURSIVE RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.ParentId,
        r.Level + 1,
        p2.Title,
        p2.CreationDate,
        p2.LastActivityDate,
        p2.ViewCount,
        p2.Score
    FROM 
        Posts p2
    JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
    AVG(COALESCE(ph.ViewCount, 0)) AS AverageViews,
    AVG(COALESCE(ph.Score, 0)) AS AverageScore,
    GROUP_CONCAT(DISTINCT tags.TagName ORDER BY tags.TagName SEPARATOR ', ') AS AssociatedTags,
    MAX(ph.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.Id = ph.PostId) tags ON TRUE
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    TotalUpVotes DESC, 
    LastPostDate DESC 
LIMIT 10;
