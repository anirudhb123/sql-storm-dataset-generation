WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.ParentId,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.PostId
)

SELECT 
    p.Title AS QuestionTitle,
    p.Id AS QuestionId,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COALESCE(SUM(vs.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(vs.DownVotes), 0) AS TotalDownVotes,
    a.OwnerDisplayName AS AcceptedAnswerOwner,
    p.CreationDate,
    MAX(CASE WHEN v.VoteTypeId = 2 THEN v.CreationDate END) AS LastUpvoteDate,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    ph.Level AS HierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id -- Join to get Accepted Answers
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
LEFT JOIN 
    (SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId) vs ON p.Id = vs.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[]) -- Assuming tags are stored as comma-separated IDs
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId -- Join for hierarchy
WHERE 
    p.PostTypeId = 1 -- Questions only
    AND p.CreationDate >= NOW() - INTERVAL '1 year' -- filter for questions created in the last year
GROUP BY 
    p.Id, p.Title, a.OwnerDisplayName, p.CreationDate, ph.Level
ORDER BY 
    TotalUpVotes DESC, TotalDownVotes ASC
LIMIT 100;

