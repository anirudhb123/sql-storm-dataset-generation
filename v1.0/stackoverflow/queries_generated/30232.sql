WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        post.Id,
        post.Title,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts post
    JOIN 
        PostHistory ph ON post.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ps.UpVotes, 0) AS UpVotes,
        COALESCE(ps.DownVotes, 0) AS DownVotes,
        ph.CloseDate,
        ph.ClosedBy,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN 
        ClosedPosts ph ON p.Id = ph.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, ps.UpVotes, ps.DownVotes, ph.CloseDate, ph.ClosedBy
),
PostRanking AS (
    SELECT 
        Title,
        UpVotes - DownVotes AS Score,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC, CreationDate ASC) AS Rank
    FROM 
        PostStats
)

SELECT 
    p.Title,
    p.CreationDate,
    p.UpVotes,
    p.DownVotes,
    p.CloseDate,
    p.ClosedBy,
    u.DisplayName AS ActiveUser,
    r.Level AS PostLevel
FROM 
    PostStats p
JOIN 
    MostActiveUsers u ON p.UpVotes > 5 AND p.DownVotes < 3
JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
WHERE 
    p.CloseDate IS NULL
ORDER BY 
    p.UpVotes DESC, p.CreationDate ASC;
