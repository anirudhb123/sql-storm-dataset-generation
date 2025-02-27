WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers for each question
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),
AggregateVotes AS (
    -- Aggregate votes per post
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostDetails AS (
    -- Joining posts with vote details and user information
    SELECT
        p.Id,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.UpVotes, 0) AS UpVotes,
        COALESCE(a.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        AggregateVotes a ON p.Id = a.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, u.DisplayName, a.UpVotes, a.DownVotes
),
ClosedPosts AS (
    -- Find closed posts with their close reason
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.Id AS PostID,
    pd.Title,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    COALESCE(cp.CloseReason, 'Open') AS PostStatus,
    COALESCE(rph.Level, 0) AS AnswerLevel
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.Id = cp.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON pd.Id = rph.PostId
WHERE 
    pd.UpVotes - pd.DownVotes > 0 -- Filter for positively scored posts
ORDER BY 
    pd.UpVotes DESC,
    pd.CommentCount DESC;
