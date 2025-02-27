WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostAggregates AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.TotalBounty, 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY ph.Level ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM 
        RecursivePostHierarchy ph
    JOIN 
        Posts ps ON ph.PostId = ps.Id
    LEFT JOIN 
        VoteSummary vs ON ps.Id = vs.PostId
)
SELECT 
    pa.Title,
    pa.Level,
    pa.ViewCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.TotalBounty,
    pa.ViewRank,
    pt.Name AS PostTypeName
FROM 
    PostAggregates pa
JOIN 
    PostTypes pt ON pa.PostTypeId = pt.Id
WHERE 
    pa.Level = 0 AND -- Top-level posts only
    pa.ViewRank <= 5 -- Top 5 by view count within each level
ORDER BY 
    pa.ViewCount DESC;

-- Include retrieval of posts that have been closed or migrated with detailed history
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate AS ClosureDate,
    p.Body,
    COALESCE(ph.Comment, 'No comments') AS ClosureComment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
ORDER BY 
    ph.CreationDate DESC;
