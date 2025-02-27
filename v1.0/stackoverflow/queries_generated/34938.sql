WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions only

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        p2.ParentId,
        p2.CreationDate,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.Id
)

SELECT 
    ph.Id AS PostId,
    ph.Title,
    ph.Level,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(u.Reputation) FILTER (WHERE u.Reputation IS NOT NULL) AS AverageReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
    MAX(p.CreationDate) AS LastActivity
FROM 
    PostHierarchy ph
LEFT JOIN 
    Comments c ON c.PostId = ph.Id
LEFT JOIN 
    Votes v ON v.PostId = ph.Id
LEFT JOIN 
    Users u ON u.Id = ph.AcceptedAnswerId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY((SELECT Tags FROM Posts WHERE Id = ph.Id), ',')) AS tagId ON CAST(tagId AS INT) = t.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(substring(ph.Tags, 2, length(ph.Tags)-2), '>,<')))

WHERE 
    ph.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    ph.Id, ph.Title, ph.Level
HAVING 
    COUNT(DISTINCT v.Id) > 5 -- Select posts with more than 5 votes
ORDER BY 
    ph.Level DESC, 
    LastActivity DESC;

