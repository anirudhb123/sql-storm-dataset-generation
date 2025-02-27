
WITH RECURSIVE RecursivePostTree AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        pt.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree pt ON p.ParentId = pt.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    rpt.Level,
    COUNT(DISTINCT p.Id) AS AnswerCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(p.Score) AS AvgScore,
    MAX(p.CreationDate) AS LastActivityDate
FROM 
    RecursivePostTree rpt
JOIN 
    Posts p ON rpt.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         t.TagName, p.Id as pId 
     FROM 
         Tags t 
     JOIN 
         Posts p ON FIND_IN_SET(t.TagName, p.Tags) > 0) AS t ON p.Id = t.pId
WHERE 
    (u.Reputation > 1000 OR u.DisplayName IS NOT NULL)
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, rpt.Level
ORDER BY 
    u.Reputation DESC, rpt.Level
LIMIT 10;
