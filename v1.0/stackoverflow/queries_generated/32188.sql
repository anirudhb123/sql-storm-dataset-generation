WITH RecursivePostHierarchy AS (
    -- CTE to get post parent-child hierarchy
    SELECT 
        Id, 
        Title, 
        ParentId, 
        0 AS HierarchyLevel
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        h.HierarchyLevel + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy h ON p.ParentId = h.Id
),
PostVoteStats AS (
    -- CTE to calculate vote statistics for posts
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RecentPosts AS (
    -- CTE to find recent posts along with their user reputation
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
),
ClosedPostHistory AS (
    -- CTE to get closed post history with reasons
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Reputation,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        ch.Comment AS ClosedComment,
        ch.CloseReason,
        COUNT(DISTINCT rph.Id) AS AnswerCount,
        NULLIF(SUM(CASE WHEN cp.ParentId IS NULL THEN 1 END), 0) AS TopLevelAnswerCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        ClosedPostHistory ch ON rp.PostId = ch.PostId
    LEFT JOIN 
        RecursivePostHierarchy rph ON rp.PostId = rph.ParentId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Reputation, ch.Comment, ch.CloseReason
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Reputation,
    UpVotes,
    DownVotes,
    ClosedComment,
    CloseReason,
    AnswerCount,
    TopLevelAnswerCount
FROM 
    FinalResult
WHERE 
    Reputation > 100 AND 
    AnswerCount > 3
ORDER BY 
    CreationDate DESC
LIMIT 20;
