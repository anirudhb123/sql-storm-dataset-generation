WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        ph.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts ph
    LEFT JOIN 
        Comments c ON ph.Id = c.PostId
    LEFT JOIN 
        Votes v ON ph.Id = v.PostId
    GROUP BY 
        ph.PostId
)

SELECT 
    rph.Title,
    u.DisplayName,
    p.CommentCount,
    p.VoteCount,
    p.UpVoteCount,
    p.DownVoteCount,
    rph.CreationDate AS QuestionCreationDate,
    rph.Level,
    CASE 
        WHEN u.TotalReputation > 1000 THEN 'High Reputation' 
        WHEN u.TotalReputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN p.CommentCount > 0 THEN 'Active' 
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    RecursivePostHierarchy rph
JOIN 
    UserReputation u ON rph.OwnerUserId = u.UserId
JOIN 
    PostStats p ON rph.PostId = p.PostId
WHERE 
    rph.Level = 0 -- Only top-level questions
ORDER BY 
    p.VoteCount DESC, 
    rph.CreationDate DESC;
