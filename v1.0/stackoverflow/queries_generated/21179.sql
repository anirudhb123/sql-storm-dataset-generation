WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.ViewCount > 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ur.Reputation,
        ur.TotalBounty,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 8) AS TotalBountyAwarded
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.PostId = ur.UserId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.Reputation,
    pd.TotalBounty,
    pd.CommentCount,
    pd.TotalBountyAwarded,
    CASE 
        WHEN pd.TotalBountyAwarded IS NULL THEN 'No Bounty Awarded'
        ELSE 'Bounty Awarded'
    END AS BountyStatus,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ', ')) WHERE p.Id = pd.PostId) AS Tags
FROM 
    PostDetails pd
WHERE 
    pd.Reputation >= 100
ORDER BY 
    pd.Score DESC,
    pd.Reputation DESC
LIMIT 10;

-- Additional Benchmarking: Count the distinct post history events for closed posts with weight
SELECT 
    COUNT(DISTINCT ph.Id) AS DistinctHistoryEvents,
    SUM(CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 1 
        ELSE 0 
        END) AS CloseEvents
FROM 
    PostHistory ph 
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    p.PostTypeId = 1
    AND p.ClosedDate IS NOT NULL;

-- Extra bizarre logic to count posts that have both tags and close history events
SELECT 
    COUNT(DISTINCT p.Id) AS ComplexPostCount
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen history
WHERE 
    p.Tags IS NOT NULL
    AND ARRAY_LENGTH(string_to_array(p.Tags, ', '), 1) > 0;
