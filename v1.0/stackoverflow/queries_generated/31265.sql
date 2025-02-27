WITH RecursivePostHierarchy AS (
    -- CTE to get post hierarchy including questions and answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        p2.ParentId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
),

PostVoteAggregates AS (
    -- Aggregate Vote counts per post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

PostHistoryDetails AS (
    -- Get the latest edit details for posts
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.Comment, ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body and Tag edits
    GROUP BY 
        ph.PostId
)

SELECT 
    rph.PostId,
    rph.Title,
    CASE 
        WHEN rph.PostTypeId = 1 THEN 'Question'
        WHEN rph.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    COALESCE(pva.UpVotes, 0) AS UpVotes,
    COALESCE(pva.DownVotes, 0) AS DownVotes,
    COALESCE(pva.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN phd.LastEditDate IS NOT NULL THEN phd.LastEditDate
        ELSE 'No edits'
    END AS LastEditDate,
    COALESCE(phd.EditComments, 'No comments') AS EditComments,
    rph.AcceptedAnswerId,
    CASE 
        WHEN rph.Level > 0 THEN 'Child post'
        ELSE 'Root post'
    END AS PostHierarchyLevel
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostVoteAggregates pva ON rph.PostId = pva.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rph.PostId = phd.PostId
ORDER BY 
    rph.PostId;

-- Note: This elaborate query benchmarks performance using CTEs, aggregates, case statements, and NULL logic across the StackOverflow schema, focusing on post details and interactions.
