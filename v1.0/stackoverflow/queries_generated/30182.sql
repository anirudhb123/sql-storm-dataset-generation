WITH RecursivePostHierarchy AS (
    -- Recursively build a hierarchy of posts (questions and answers)
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.OwnerUserId,
        CAST(p.Title AS VARCHAR(MAX)) AS FullHierarchy
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        ph.Level + 1,
        p.Title,
        p.OwnerUserId,
        CAST(ph.FullHierarchy + ' -> ' + p.Title AS VARCHAR(MAX)) 
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  -- Answer posts
),
UserEngagement AS (
    -- Calculate user engagement levels based on votes and posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    -- Filter for posts that have been closed and their close reasons
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment::INTEGER = c.Id
),
PostDetails AS (
    -- Combine posts with their engagement and closure information
    SELECT 
        ph.PostId,
        ph.Level,
        ph.Title,
        ph.OwnerUserId,
        ue.TotalPosts,
        ue.TotalVotes,
        ue.UpVotes,
        ue.DownVotes,
        cp.ClosedDate,
        cp.CloseReason,
        ue.Rank
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        UserEngagement ue ON ph.OwnerUserId = ue.UserId
    LEFT JOIN 
        ClosedPosts cp ON ph.PostId = cp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Level,
    pd.TotalPosts,
    pd.TotalVotes,
    pd.UpVotes,
    pd.DownVotes,
    pd.ClosedDate,
    COALESCE(pd.CloseReason, 'Not Closed') AS CloseReason,
    CASE 
        WHEN pd.Rank IS NULL THEN 'No Engagement'
        ELSE pd.Rank::VARCHAR
    END AS EngagementRank
FROM 
    PostDetails pd
WHERE 
    (pd.ClosedDate IS NOT NULL OR pd.TotalPosts > 5) AND  -- Filter for engagement or closed posts
    pd.UpVotes > pd.DownVotes  -- Positive engagement posts
ORDER BY 
    pd.UpVotes DESC
LIMIT 100;  -- Limit the results for performance benchmarking
