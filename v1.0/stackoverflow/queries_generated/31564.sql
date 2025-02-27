WITH RecursivePostHierarchy AS (
    -- CTE to create a hierarchy of posts and their accepted answers
    SELECT 
        Id AS PostId,
        AcceptedAnswerId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2  -- Joining with answers
),

-- CTE to get the latest edits for each post
LatestEdits AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LatestEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
    GROUP BY 
        PostId
),

UserActivity AS (
    -- Aggregating user votes to get the total activity score
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

-- Main query to fetch detailed information about questions, answers, and user activity
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.CreationDate AS QuestionDate,
    q.AnswerCount,
    q.Score AS QuestionScore,
    COALESCE(a.Id, 0) AS AcceptedAnswerId, 
    COALESCE(a.Body, 'No accepted answer') AS AcceptedAnswerBody,
    a.LastEditDate AS AcceptedAnswerLastEdit,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    ua.VoteCount AS UserActivityVoteCount,
    ua.UpvoteCount AS UserActivityUpvoteCount,
    ua.DownvoteCount AS UserActivityDownvoteCount,
    ph.LatestEditDate AS PostLatestEditDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts q
LEFT JOIN 
    Posts a ON q.AcceptedAnswerId = a.Id
LEFT JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    LatestEdits ph ON q.Id = ph.PostId
LEFT JOIN 
    LATERAL STRING_TO_ARRAY(q.Tags, ',') AS t ON TRUE
WHERE 
    q.PostTypeId = 1  -- Filtering for questions
GROUP BY 
    q.Id, a.Id, u.Id, ua.UserId, ph.LatestEditDate
ORDER BY 
    q.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;  -- Limit the results for performance benchmarking
