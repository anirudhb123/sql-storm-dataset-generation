WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerDisplayName,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.OwnerDisplayName,
        a.CreationDate,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        PostHierarchy ph ON q.Id = ph.PostId
)

SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.OwnerDisplayName AS QuestionOwner,
    ph.PostId AS AnswerId,
    ph.Title AS AnswerTitle,
    ph.OwnerDisplayName AS AnswerOwner,
    ph.Level AS AnswerLevel,
    pv.TotalVotes,
    uv.Reputation AS UserReputation,
    ba.BadgeCount,
    CASE 
        WHEN ph.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old Answer'
        ELSE 'New Answer'
    END AS AnswerAgeCategory
FROM 
    PostHierarchy ph 
JOIN 
    Posts p ON ph.PostId = p.AcceptedAnswerId  -- link to questions where the answer is accepted
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS TotalVotes 
     FROM 
        Votes 
     WHERE 
        VoteTypeId IN (2, 3)  -- Counting upvotes and downvotes
     GROUP BY 
        PostId) pv ON pv.PostId = ph.PostId
JOIN 
    Users uv ON ph.OwnerDisplayName = uv.DisplayName
LEFT JOIN 
    (SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
     FROM 
        Badges 
     GROUP BY 
        UserId) ba ON ba.UserId = uv.Id
WHERE 
    ph.PostTypeId = 2  -- Only Answers
ORDER BY 
    p.CreationDate DESC,
    ph.Level DESC;
