WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting from top-level posts (Questions)

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        rh.Level + 1,
        CAST(rh.Path + ' -> ' + p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rh ON p.ParentId = rh.PostId
),
PostMetrics AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.ViewCount,
        ph.Score,
        ph.Level,
        ph.Path,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId, ph.Title, ph.ViewCount, ph.Score, ph.Level, ph.Path
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, Score, Level, Path, 
        UpVotes - DownVotes AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY Level ORDER BY Score DESC, ViewCount DESC) AS rn
    FROM 
        PostMetrics
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.NetVotes,
    tp.Path,
    CASE 
        WHEN tp.UpVotes > 0 THEN 'Popular'
        WHEN tp.CloseVotes > 0 THEN 'Closed'
        ELSE 'Other'
    END AS PostStatus
FROM 
    TopPosts tp
WHERE 
    tp.rn <= 10  -- Limit to top 10 posts at each level
ORDER BY 
    tp.Level, tp.Score DESC;
