WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS PostLevel
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ph.PostLevel + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RecentPostStats AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        PostStats ps
    JOIN 
        Posts p ON ps.PostId = p.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.OwnerUserId,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    rph.PostLevel,
    CASE 
        WHEN ps.CommentCount IS NULL THEN 'No Comments'
        WHEN ps.CommentCount > 0 THEN 'Has Comments'
        ELSE 'Not Applicable'
    END AS CommentStatus
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    UserReputation ur ON rph.OwnerUserId = ur.UserId
LEFT JOIN 
    RecentPostStats ps ON rph.PostId = ps.PostId
WHERE 
    rph.PostLevel < 4  -- Limiting to a hierarchy level of 3
ORDER BY 
    ur.Reputation DESC, rph.CreationDate DESC;
