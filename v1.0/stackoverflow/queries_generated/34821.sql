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
        p2.Id,
        p2.Title,
        p2.ParentId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    r.PostId,
    r.Title,
    r.Level,
    ps.TotalBounty,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ur.Reputation,
    ur.ReputationRank
FROM 
    RecursivePostHierarchy r
JOIN 
    PostStatistics ps ON r.PostId = ps.PostId
JOIN 
    Users u ON ps.PostId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    ps.UpVotes > ps.DownVotes
ORDER BY 
    ps.TotalBounty DESC, ur.ReputationRank;
