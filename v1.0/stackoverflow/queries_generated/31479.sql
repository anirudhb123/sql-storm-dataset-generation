WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.PostTypeId,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phe.EditCount, 0) AS TotalEdits,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN ph.PostTypeId = 1 AND ph.ParentId IS NULL THEN 'Question'
        WHEN ph.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostClassification,
    CASE 
        WHEN ph.Level > 1 THEN 'Child Post'
        ELSE 'Root Post'
    END AS PostRelationship
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteStats ps ON ph.PostId = ps.Id
LEFT JOIN 
    PostHistoryCounts phe ON ph.PostId = phe.PostId
LEFT JOIN 
    PostsWithComments pc ON ph.PostId = pc.PostId
ORDER BY 
    ph.Level, ph.Title;

-- Additional performance benchmarking on filtering, ordering, and case handling:
EXPLAIN ANALYZE
SELECT 
    ph.PostId,
    ph.Title,
    CASE 
        WHEN UpVotes = 0 THEN 'No Votes'
        WHEN UpVotes < 10 THEN 'Few Votes'
        ELSE 'Popular Post'
    END AS Popularity,
    ROUND(COALESCE(ps.UpVotes, 0)::decimal / NULLIF(COALESCE(pc.CommentCount, 0), 0), 2) AS UpVotePerCommentRatio
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteStats ps ON ph.PostId = ps.Id
LEFT JOIN 
    PostsWithComments pc ON ph.PostId = pc.PostId
WHERE 
    ph.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
ORDER BY 
    UpVotePerCommentRatio DESC;
