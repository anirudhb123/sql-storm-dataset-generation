WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CASE 
            WHEN Reputation >= 10000 THEN 'High Reputational User'
            WHEN Reputation >= 1000 THEN 'Moderate Reputational User'
            ELSE 'Low Reputational User'
        END AS ReputationCategory
    FROM 
        Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount,
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpVote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownVote,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
),
CloseReasons AS (
    SELECT 
        PostId, 
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        PostId
),
FinalReport AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.ViewCount, 
        ps.CommentCount, 
        ps.VoteCount, 
        u.ReputationCategory, 
        cr.CloseCount, 
        cr.CloseReasons,
        COALESCE(ps.HasUpVote, 0) AS UpVoteFlag,
        COALESCE(ps.HasDownVote, 0) AS DownVoteFlag
    FROM 
        PostStats ps
    LEFT JOIN 
        Users u ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = ps.PostId)
    LEFT JOIN 
        CloseReasons cr ON cr.PostId = ps.PostId 
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    (CloseCount > 0 OR UpVoteFlag = 1)
ORDER BY 
    CloseCount DESC, 
    VoteCount DESC, 
    ViewCount DESC
LIMIT 100;

This SQL query performs a complex analysis across various aspects of the Stack Overflow schema. It utilizes Common Table Expressions (CTEs) to segment user reputation, post statistics, and the reasoning behind closed posts. The final report aggregates this data and filters it based on specific logic, showing only the posts that have been closed or upvoted, while also ranking them by their closure statuses and engagement metrics.
