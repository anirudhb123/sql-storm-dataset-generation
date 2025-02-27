WITH RecursivePostHierarchy AS (
    -- This CTE will help build a hierarchy of posts where we can find parents and accepted answers
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        Level + 1,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),

PostStats AS (
    -- Calculate total votes and comments for each post
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),

FlaggedPosts AS (
    -- Identify posts that have been closed or deleted
    SELECT 
        p.Id,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS IsClosedOrDeleted
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),

FinalPostStats AS (
    -- Combine data from previous CTEs along with filtering based on post status
    SELECT 
        rph.PostId,
        rph.Title,
        rph.CreationDate,
        rph.ViewCount,
        rph.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        fp.IsClosedOrDeleted,
        ROW_NUMBER() OVER (PARTITION BY fp.IsClosedOrDeleted ORDER BY rph.Score DESC) AS Rank
    FROM 
        RecursivePostHierarchy rph
    JOIN 
        PostStats ps ON rph.PostId = ps.PostId
    JOIN 
        FlaggedPosts fp ON rph.PostId = fp.Id
    WHERE 
        fp.IsClosedOrDeleted = 0  -- Only include open posts
)

-- Final selection for benchmarking
SELECT 
    Title,
    CreationDate,
    ViewCount,
    Score,
    UpVotes,
    DownVotes,
    CommentCount,
    Rank
FROM 
    FinalPostStats
WHERE 
    Rank <= 10  -- Get top 10 posts based on score
ORDER BY 
    Score DESC;
