WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
UserReputationRanking AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
ClosedPostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.PostId) AS CloseReasonsCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS ClosedReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = ph.Comment::int
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- indicate post closed
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    rph.Title,
    rph.CreationDate,
    COALESCE(ur.Reputation, 0) AS UserReputation,
    ur.ReputationRank,
    COALESCE(cps.CloseReasonsCount, 0) AS ClosedReasons,
    COALESCE(cps.ClosedReasonNames, 'None') AS ClosedReasonNames,
    COALESCE(pv.Score, 0) AS PostScore,
    rph.Level
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    Users u ON u.Id = rph.Id
LEFT JOIN 
    UserReputationRanking ur ON ur.UserId = u.Id
LEFT JOIN 
    ClosedPostStats cps ON cps.PostId = rph.Id
LEFT JOIN 
    PostVotes pv ON pv.PostId = rph.Id
WHERE 
    rph.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    rph.Level, ur.Reputation DESC;
This query extracts retrieved data from multiple tables, showcasing the hierarchy of posts, user reputations, closure statistics, and voting outcomes. It utilizes recursive CTEs to showcase a hierarchy of posts, ranks users by reputation, gathers close reasons, and computes post scores with window functions and aggregate calculations.
