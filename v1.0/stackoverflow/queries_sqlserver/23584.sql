
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId
),
EnhancedPostInfo AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(ps.CloseOpenCount, 0) AS CloseOpenCount,
        COALESCE(ps.DeletionCount, 0) AS DeletionCount,
        ps.LastActivityDate,
        ur.Reputation AS OwnerReputation,
        ur.TotalBounties
    FROM 
        RankedPosts rp
        LEFT JOIN PostHistorySummary ps ON rp.PostId = ps.PostId
        LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    epi.PostId,
    epi.Title,
    epi.CreationDate,
    epi.Score,
    epi.CloseOpenCount,
    epi.DeletionCount,
    epi.OwnerReputation,
    CASE 
        WHEN epi.OwnerReputation >= 1000 THEN 'Elite' 
        WHEN epi.OwnerReputation BETWEEN 500 AND 999 THEN 'Experienced' 
        ELSE 'Novice' 
    END AS UserCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    EnhancedPostInfo epi
    LEFT JOIN Posts p ON epi.PostId = p.Id
    CROSS APPLY (
        SELECT 
            value AS TagName
        FROM STRING_SPLIT(p.Tags, ', ')
    ) t
GROUP BY 
    epi.PostId, epi.Title, epi.CreationDate, epi.Score, epi.CloseOpenCount, epi.DeletionCount, epi.OwnerReputation
ORDER BY 
    epi.Score DESC, epi.CloseOpenCount DESC;
