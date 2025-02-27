WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),

PostCloseHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.UserDisplayName,
        ph.CreationDate AS CloseDate,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No comment provided'
        END AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only consider closed and reopened
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM 
        Users u
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pch.CloseDate, 'Not Closed') AS LastCloseDate,
        COALESCE(pch.CloseReason, 'N/A') AS LastCloseReason,
        ur.ReputationCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCloseHistory pch ON rp.PostId = pch.PostId AND pch.CloseRank = 1 -- Latest close event
    INNER JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON ur.UserId = u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.OwnerDisplayName,
    ps.LastCloseDate,
    ps.LastCloseReason,
    ps.ReputationCategory,
    CASE 
        WHEN ps.Score > 100 THEN 'Highly Valuable'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Valuable'
        ELSE 'Less Valuable'
    END AS ValueCategory
FROM 
    PostStatistics ps
WHERE 
    ps.ReputationCategory <> 'Unknown'
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC
LIMIT 100;

-- Additional analytics for posts with specific tags
SELECT 
    p.Id AS PostId,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    STRING_TO_ARRAY(p.Tags, '<>') AS tagName ON TRUE -- simulate tag split (handling NULL logic of tags)
LEFT JOIN 
    Tags t ON t.TagName = tagName
GROUP BY 
    p.Id
HAVING 
    COUNT(t.TagName) >= 2  -- Posts with at least 2 valid tags
ORDER BY 
    p.Id;

-- Check for users with excessive post closure actions
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(ph.Id) AS ClosureCount
FROM 
    Users u
JOIN 
    PostHistory ph ON u.Id = ph.UserId
WHERE 
    ph.PostHistoryTypeId = 10  -- Counting how many posts a user has closed
GROUP BY 
    u.Id
HAVING 
    COUNT(ph.Id) > 10 -- Users who have closed more than 10 posts
ORDER BY 
    ClosureCount DESC;
