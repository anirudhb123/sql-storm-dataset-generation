WITH RecursivePostHierarchy AS (
    -- Recursive Common Table Expression to get the post hierarchy
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
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
        p.CreationDate,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStats AS (
    -- Common Table Expression to gather post statistics
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId) AS Score,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopTags AS (
    -- Common Table Expression to get top tags based on post count
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON t.Id = pt.Tags::int[]  -- Assuming Tags can be treated as an array of integers
    WHERE 
        pt.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    ps.CommentCount,
    ps.Score,
    ps.LastBadgeDate,
    tt.TagName AS TopTag
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    PostStats ps ON r.PostId = ps.PostId
LEFT JOIN 
    TopTags tt ON tt.PostCount > 0  -- Joining with top tags
WHERE 
    ps.CommentCount > 10  -- Filtering for posts with considerable comments
ORDER BY 
    r.CreationDate DESC
LIMIT 100;

-- Evaluating performance of the query by running an EXPLAIN plan
EXPLAIN ANALYZE 
WITH RecursivePostHierarchy AS (
    -- Recursive Common Table Expression to get the post hierarchy
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
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
        p.CreationDate,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStats AS (
    -- Common Table Expression to gather post statistics
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId) AS Score,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopTags AS (
    -- Common Table Expression to get top tags based on post count
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON t.Id = pt.Tags::int[]  -- Assuming Tags can be treated as an array of integers
    WHERE 
        pt.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    ps.CommentCount,
    ps.Score,
    ps.LastBadgeDate,
    tt.TagName AS TopTag
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    PostStats ps ON r.PostId = ps.PostId
LEFT JOIN 
    TopTags tt ON tt.PostCount > 0  -- Joining with top tags
WHERE 
    ps.CommentCount > 10 
