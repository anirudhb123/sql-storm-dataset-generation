WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
    WHERE 
        p2.PostTypeId = 2 -- Only answers
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    COALESCE(h.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(h.EditCount, 0) AS EditCount,
    u.DisplayName AS TopUserDisplayName,
    u.Reputation,
    rh.Level AS AnswerLevel
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryAggregate h ON ps.PostId = h.PostId
LEFT JOIN 
    TopUsers u ON ps.Score = (SELECT MAX(Score) FROM Posts WHERE ParentId = ps.PostId) -- Top user for this question's answers
LEFT JOIN 
    RecursivePostHierarchy rh ON ps.PostId = rh.PostId
WHERE 
    ps.AnswerCount > 0 -- Questions with at least one answer
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC;
