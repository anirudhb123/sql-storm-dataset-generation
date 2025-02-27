WITH RecursivePostTree AS (
    -- Base case: Select all questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    -- Recursive case: Join answers to their questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),
AggregatedPostStats AS (
    SELECT 
        p.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RecursivePostTree p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    EXTRACT(EPOCH FROM (COALESCE(he.LastEditDate, '1970-01-01'::timestamp) - p.CreationDate)) AS TimeSinceCreation,
    he.FirstEditDate,
    he.LastEditDate,
    he.EditCount,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM 
    RecursivePostTree p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    AggregatedPostStats ps ON p.PostId = ps.PostId
LEFT JOIN 
    PostHistoryStats he ON p.PostId = he.PostId
WHERE 
    (ps.UpVoteCount - ps.DownVoteCount > 5)  -- Filter for popular posts
    AND (he.EditCount > 3 OR he.FirstEditDate IS NOT NULL)
ORDER BY 
    TimeSinceCreation DESC
LIMIT 10;
