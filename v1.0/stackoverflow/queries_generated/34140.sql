WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1           -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        c.Comment AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment = CAST(c.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10      -- Post Closed
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AverageCommentLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
FinalResult AS (
    SELECT 
        p.Title,
        u.DisplayName AS OwnerName,
        ur.Reputation AS OwnerReputation,
        COALESCE(ps.UpVotes, 0) AS UpVotes,
        COALESCE(ps.DownVotes, 0) AS DownVotes,
        COALESCE(ps.TotalVotes, 0) AS TotalVotes,
        COALESCE(cl.CloseReason, 'Not Closed') AS CloseReason,
        ph.Comments AS CommentCount,
        ph.AverageCommentLength,
        r.Level AS HierarchyLevel
    FROM 
        Posts p
    LEFT JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN 
        ClosedPosts cl ON p.Id = cl.PostId
    LEFT JOIN 
        PostWithComments ph ON p.Id = ph.PostId
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.PostId
)
SELECT 
    Title,
    OwnerName,
    OwnerReputation,
    UpVotes,
    DownVotes,
    TotalVotes,
    CloseReason,
    CommentCount,
    AverageCommentLength,
    HierarchyLevel
FROM 
    FinalResult
WHERE 
    OwnerReputation > 500    -- Filter for users with reputation greater than 500
ORDER BY 
    UpVotes DESC, HierarchyLevel ASC; -- Order by number of upvotes and hierarchy
