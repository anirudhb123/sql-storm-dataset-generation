WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
PostHistoryEntry AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeleted,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ur.ReputationLevel,
        COALESCE(ph.LastDeleted, ph.LastClosed) AS LastActionDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistoryEntry ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn = 1 AND -- Only the most recent post per type
        (COALESCE(ph.LastDeleted, ph.LastClosed) IS NOT NULL OR ur.ReputationLevel = 'High') -- peculiar condition to include posts that are either recently acted upon or from high-reputation users
)
SELECT 
    fo.Title,
    fo.ReputationLevel,
    fo.LastActionDate,
    CASE 
        WHEN fo.LastActionDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    FinalOutput fo
WHERE 
    fo.CommentCount > 10 -- Filter for posts with more than 10 comments
ORDER BY 
    fo.ReputationLevel DESC,
    fo.LastActionDate DESC
LIMIT 100; -- Limit the output to top 100 posts

