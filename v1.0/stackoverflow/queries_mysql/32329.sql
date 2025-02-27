
WITH PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        a.CreationDate,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.Id
    WHERE 
        a.PostTypeId = 2 
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT ph.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN ph.AcceptedAnswerId IS NOT NULL THEN ph.AcceptedAnswerId END) AS AcceptedAnswers,
    AVG(TIMESTAMPDIFF(SECOND, ph.CreationDate, '2024-10-01 12:34:56') / 3600) AS AvgAgeInHours,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM 
    PostHierarchy ph
JOIN 
    Users u ON ph.OwnerUserId = u.Id
LEFT JOIN 
    Posts ans ON ph.Id = ans.ParentId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = ph.Id
LEFT JOIN 
    Votes v ON v.PostId = ph.Id
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT ph.Id) > 1 
    AND AVG(TIMESTAMPDIFF(SECOND, ph.CreationDate, '2024-10-01 12:34:56') / 3600) < 24
ORDER BY 
    TotalPosts DESC
LIMIT 10;
