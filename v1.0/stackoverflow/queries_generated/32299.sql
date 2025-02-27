WITH RecursivePostHierarchy AS (
    -- Base case: get all questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1

    UNION ALL

    -- Recursive case: get answers linked to the questions
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy q ON a.ParentId = q.PostId
)

-- Main query
SELECT 
    p.Title AS QuestionTitle,
    COUNT(a.Id) AS AnswerCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
    AVG(u.Reputation) AS AverageReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    p.CreationDate,
    ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY a.CreationDate DESC) AS RecentAnswerRank
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Votes v ON a.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag ON t.TagName = TRIM(tag.value)
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, p.CreationDate
HAVING 
    COUNT(a.Id) > 0
ORDER BY 
    UpVoteCount DESC, AnswerCount DESC;

-- Get the history of closed posts with their close reasons
SELECT 
    ph.PostId,
    ph.CreationDate AS HistoryDate,
    p.Title AS PostTitle,
    chr.Name AS CloseReason
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    CloseReasonTypes chr ON ph.Comment::int = chr.Id -- Assuming the close reason is stored as a string representation of an int
WHERE 
    ph.PostHistoryTypeId = 10 -- Post Closed
    AND p.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY 
    ph.CreationDate DESC;

-- Advanced analysis of user activities with window functions
SELECT 
    u.DisplayName, 
    COUNT(DISTINCT p.Id) AS PostsCreated,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation > 1000 -- Only users with significant reputation
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 posts
ORDER BY 
    PostsCreated DESC;
