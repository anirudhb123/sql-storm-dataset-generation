WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostStats AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(v.BountyAmount) AS AverageBounty,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.LastActivityDate >= DATEADD(MONTH, -6, GETDATE())  -- Last 6 months activity
    GROUP BY 
        p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
),
RecentActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.LastActivityDate >= DATEADD(DAY, -30, GETDATE())  -- Active in the last 30 days
),
FinalResults AS (
    SELECT 
        p.Title,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AverageBounty,
        COALESCE(ch.CloseReason, 'Not Closed') AS CloseReason,
        rah.PostId,
        rah.Level
    FROM 
        PostStats ps
    JOIN 
        Posts p ON ps.Id = p.Id
    LEFT JOIN 
        ClosedPostHistory ch ON p.Id = ch.PostId
    LEFT JOIN 
        RecursivePostHierarchy rah ON p.Id = rah.PostId
)
SELECT 
    fr.Title,
    fr.CommentCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.AverageBounty,
    fr.CloseReason,
    ISNULL(NULLIF(fr.Level, 1), -1) AS HierarchyLevel -- -1 signifies no hierarchy
FROM 
    FinalResults fr
ORDER BY 
    fr.UpVoteCount DESC, 
    fr.CommentCount DESC;
