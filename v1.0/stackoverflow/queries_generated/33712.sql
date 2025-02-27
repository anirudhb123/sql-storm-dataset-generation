WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(p2.Id) OVER (PARTITION BY p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts p2 ON p.Id = p2.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.UpVotes - ps.DownVotes) AS NetVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ph.Title,
    ph.Level,
    us.DisplayName,
    us.NetVotes,
    us.AvgReputation,
    CASE 
        WHEN us.NetVotes >= 100 THEN 'High Performer'
        WHEN us.NetVotes BETWEEN 50 AND 99 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    UserScores us ON ph.OwnerUserId = us.UserId
ORDER BY 
    us.NetVotes DESC, 
    ph.Level, 
    ph.Title;
