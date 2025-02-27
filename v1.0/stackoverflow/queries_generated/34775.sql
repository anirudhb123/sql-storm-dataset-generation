WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
AnswerStatistics AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS AnswerCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveAnswerCount,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeAnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 2 -- Answers only
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.PositiveAnswerCount, 0) AS PositiveAnswerCount,
        COALESCE(ps.NegativeAnswerCount, 0) AS NegativeAnswerCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        AnswerStatistics ps ON u.Id = ps.OwnerUserId
),
PostEditHistory AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId = 5 THEN ph.CreationDate END) AS LastBodyEdit
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.AnswerCount,
    ur.PositiveAnswerCount,
    ur.NegativeAnswerCount,
    pe.LastTitleEdit,
    pe.LastBodyEdit,
    COALESCE(rph.Level, 0) AS QuestionLevel,
    COALESCE(rph.Title, 'N/A') AS ParentTitle
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    Posts q ON q.OwnerUserId = u.Id AND q.PostTypeId = 1 -- Questions only
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.Id = q.ParentId 
LEFT JOIN 
    PostEditHistory pe ON pe.PostId = q.Id
WHERE 
    ur.Rank <= 10 
ORDER BY 
    u.Reputation DESC;
