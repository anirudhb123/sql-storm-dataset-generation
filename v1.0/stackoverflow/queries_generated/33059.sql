WITH RecursivePostHierarchy AS (
    -- CTE to build a hierarchy of posts and their answers
    SELECT 
        Id AS PostId, 
        Title, 
        ParentId, 
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ParentId, 
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Only answers
),

PostStats AS (
    -- Aggregating post statistics including upvotes, downvotes, and comments
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(bb.Class), 0) AS TotalBadges
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges bb ON p.OwnerUserId = bb.UserId AND bb.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),

CloseReasons AS (
    -- Extracting close reasons for closed questions
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),

FinalReport AS (
    SELECT 
        rph.PostId,
        rph.Title,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        cr.CloseReasons,
        rph.Level
    FROM 
        RecursivePostHierarchy rph
    LEFT JOIN 
        PostStats ps ON rph.PostId = ps.Id
    LEFT JOIN 
        CloseReasons cr ON rph.PostId = cr.PostId
)

-- Selecting final results with window functions to rank posts
SELECT 
    PostId,
    Title,
    UpVotes,
    DownVotes,
    CommentCount,
    COALESCE(CloseReasons, 'Not Closed') AS CloseReasons,
    Level,
    RANK() OVER (PARTITION BY Level ORDER BY UpVotes DESC) AS VoteRank
FROM 
    FinalReport
ORDER BY 
    Level, UpVotes DESC;
