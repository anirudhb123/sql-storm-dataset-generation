WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- starting with top-level posts
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        p.Score,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(CAST(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS bigint), 0) AS UpVotes,
        COALESCE(CAST(NULLIF(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS bigint), 0) AS DownVotes,
        COALESCE(CAST(NULLIF(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS bigint), 0) AS AcceptedVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostWithStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ps.UpVotes,
        ps.DownVotes,
        ps.AcceptedVotes,
        ph.Level
    FROM 
        Posts p
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.PostId
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY Level ORDER BY UpVotes DESC) AS Rank
    FROM 
        PostWithStatistics
)
SELECT 
    u.DisplayName AS UserName,
    p.Title,
    p.CreationDate,
    p.UpVotes,
    p.DownVotes,
    p.AcceptedVotes,
    p.Rank
FROM 
    TopPosts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.Rank <= 5
ORDER BY 
    p.Level, p.UpVotes DESC;

