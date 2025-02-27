WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ParentId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.DisplayName AS OwnerDisplayName,
    p.Title AS QuestionTitle,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COALESCE(MAX(b.Class), 0) AS MaxBadgeLevel,
    ROUND(AVG(COALESCE(DATEDIFF(SECOND, p.CreationDate, p.LastEditDate), 0))::numeric, 2) AS AvgEditTimeSeconds,
    ph.Level AS HierarchyLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers to questions
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT id FROM string_to_array(p.Tags, '><')::int[])
LEFT JOIN 
    PostHierarchy ph ON ph.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName, p.Title, ph.Level
HAVING 
    COUNT(DISTINCT a.Id) > 0  -- Only questions with answers
ORDER BY 
    AvgEditTimeSeconds DESC, 
    UpVotes DESC;

