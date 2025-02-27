WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(1) OVER (PARTITION BY p.OwnerUserId) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    up.ReputationCategory,
    COALESCE(v.UpVotes, 0) AS UpVoteCount,
    COALESCE(v.DownVotes, 0) AS DownVoteCount,
    CASE 
        WHEN cp.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    cp.LastCloseDate
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1  -- Get the latest post for each user
LEFT JOIN 
    PostVoteCounts v ON rp.PostId = v.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.Reputation > 0 AND 
    (rp.PostTypeId = 1 OR rp.PostTypeId IS NULL) -- Include only questions or no post type
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC
LIMIT 100;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
PostDepth AS (
    SELECT 
        *,
        COUNT(Id) OVER (PARTITION BY Level ORDER BY Title) AS DepthCount
    FROM 
        PostHierarchy
)
SELECT 
    pd.Level,
    pd.DepthCount,
    STRING_AGG(pd.Title, '; ') AS PostTitles
FROM 
    PostDepth pd
GROUP BY 
    pd.Level
HAVING 
    COUNT(pd.Id) > 10;  -- Keeping only levels with more than 10 posts
