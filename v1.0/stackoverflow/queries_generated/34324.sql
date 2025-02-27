WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Select top-level posts

    UNION ALL

    SELECT 
        p.Id AS PostId, 
        p.ParentId, 
        p.Title, 
        r.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostVotes AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(ph.Id) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Filter to only closed posts
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    r.Level,
    u.Reputation AS OwnerReputation,
    ups.UpVotes,
    downs.DownVotes,
    b.BadgeCount,
    COALESCE(c.CloseVoteCount, 0) AS CloseVoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputationSummary ups ON u.Id = ups.UserId
LEFT JOIN 
    UserReputationSummary downs ON u.Id = downs.UserId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
LEFT JOIN 
    ClosedPostVotes c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId  -- Rejoining badges to get the badge count
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
AND 
    (p.Score > 10 OR (p.AcceptedAnswerId IS NOT NULL AND p.AcceptedAnswerId > 0))  -- Complexity in predicates
ORDER BY 
    u.Reputation DESC, -- Order by reputation first
    p.Score DESC;  -- then by post score

This SQL query utilizes recursive common table expressions (CTEs) to establish a hierarchy of posts based on parent-child relationships, aggregates user reputations and posts with closed votes, and includes various joins to unite related data. It also filters results based on specific criteria, demonstrating complexity in predicates and expressions while finally ordering the result set effectively.
