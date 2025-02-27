WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Score,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Select questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COUNT(DISTINCT aa.Id) AS AcceptedAnswerCount,
    ROUND(AVG(u.Reputation), 2) AS AverageReputation,
    MAX(p.CreationDate) AS MostRecentPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsAssociated,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts aa ON p.AcceptedAnswerId = aa.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Votes v ON v.UserId = u.Id
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)  -- Filter users above average reputation
    AND p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Posts created in the last year
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- Only users with more than 5 questions
ORDER BY 
    QuestionCount DESC, 
    AverageReputation DESC
LIMIT 10;

-- Adding performance analysis of posts edited multiple times in the last year
WITH EditHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 YEAR'
        AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
    HAVING EditCount > 2  -- Focus on posts edited more than twice
)
SELECT 
    p.Id AS PostId,
    p.Title,
    e.EditCount,
    e.LastEditDate,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    EditHistory e ON p.Id = e.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
ORDER BY 
    e.EditCount DESC;

-- Optional: Additional analytics for closed posts
SELECT 
    p.Title,
    ph.CreationDate AS CloseDate,
    u.DisplayName AS ClosedBy,
    crc.Name AS CloseReason
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    Users u ON ph.UserId = u.Id
JOIN 
    CloseReasonTypes crc ON ph.Comment::jsonb->>'CloseReasonId'::int = crc.Id
WHERE 
    ph.PostHistoryTypeId = 10  -- Closed posts
ORDER BY 
    ph.CreationDate DESC
LIMIT 50;
