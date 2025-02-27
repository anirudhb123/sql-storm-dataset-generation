WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        OwnerUserId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of UpVotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count of DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(pHD.ClosedDate, 'No Closure') AS ClosureStatus,
    COALESCE(ARRAY_AGG(DISTINCT t.TagName), '{}') AS Tags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    ROW_NUMBER() OVER (PARTITION BY ps.UserId ORDER BY ps.Reputation DESC) AS RankWithinUser
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStats ps ON u.Id = ps.UserId
LEFT JOIN 
    PostHistoryDetails pHD ON p.Id = pHD.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS TagName
    ) AS t ON TRUE
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
    AND (ps.UpVotes - ps.DownVotes) > 5
GROUP BY 
    p.Id, u.DisplayName, ps.UserId, ps.UpVotes, ps.DownVotes, pHD.ClosedDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
