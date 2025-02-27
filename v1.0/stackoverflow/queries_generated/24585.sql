WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.PostTypeId = 1  -- Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(*) AS TotalChanges
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS Owner,
    rp.CommentCount,
    COALESCE(phs.CloseCount, 0) AS CloseCount,
    COALESCE(phs.ReopenCount, 0) AS ReopenCount,
    rp.TotalBounty,
    ur.ReputationLevel,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest Post' 
        ELSE 'Older Post' 
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 5  -- Only the latest 5 posts per user
ORDER BY 
    rp.CreationDate DESC,  -- Order by post creation date
    ur.Reputation DESC;  -- Then by user reputation
