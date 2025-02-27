WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostAnalytics AS (
    SELECT 
        r.PostId,
        r.Title,
        ph.ParentId,
        ps.UpVotes,
        ps.DownVotes,
        r.Level,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.ParentId IS NOT NULL THEN 1 ELSE 0 END), 0) AS ChildPosts
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        VoteSummary ps ON r.PostId = ps.PostId
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        RecursivePostHierarchy ph ON r.PostId = ph.ParentId
    GROUP BY 
        r.PostId, ps.UpVotes, ps.DownVotes, r.Title, ph.ParentId, r.Level
),
TopPosts AS (
    SELECT 
        pa.*,
        ROW_NUMBER() OVER (PARTITION BY pa.Level ORDER BY pa.UpVotes DESC) AS Rank
    FROM 
        PostAnalytics pa
)
SELECT 
    t.PostId,
    t.Title,
    t.UpVotes,
    t.DownVotes,
    t.CommentCount,
    t.ChildPosts,
    t.Level 
FROM 
    TopPosts t
WHERE 
    t.Rank <= 5
ORDER BY 
    t.Level, t.UpVotes DESC;
