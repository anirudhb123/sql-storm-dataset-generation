
WITH RECURSIVE RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.OwnerUserId,
        rph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT a.Id) AS AcceptedAnswerCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    AVG(COALESCE(a.Score, 0)) AS AvgAcceptedAnswerScore,
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsUsed,
    LISTAGG(DISTINCT COALESCE(ph.UserDisplayName, 'Not Edited'), ', ') WITHIN GROUP (ORDER BY ph.UserDisplayName) AS Editors
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 
LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = p.Id 
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            SPLIT(TRIM(BOTH '}' FROM TRIM(BOTH '{' FROM p.Tags)), '>') AS TagName
    ) t ON true
WHERE 
    u.Reputation > 100 
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    QuestionCount DESC
LIMIT 10;
