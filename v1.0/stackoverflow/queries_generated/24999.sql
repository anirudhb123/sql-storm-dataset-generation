WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS MostUpvoted
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
OlderPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.PostTypeName
    FROM RankedPosts rp
    WHERE rp.rn > 1
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    COALESCE(MIN(ops.ViewCount), 0) AS MinOlderPostViews,
    COALESCE(MAX(ops.ViewCount), 0) AS MaxOlderPostViews,
    SUM(CASE WHEN phs.HistoryCount IS NOT NULL THEN phs.HistoryCount ELSE 0 END) AS PostHistoryCount,
    SUM(rp.MostUpvoted) AS TotalMostUpvotedPosts
FROM 
    Users u
JOIN 
    Posts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    OlderPosts ops ON rp.Id = ops.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    u.Reputation > 1000 OR u.AccountId IS NOT NULL
GROUP BY 
    u.DisplayName
HAVING 
    SUM(rp.ViewCount) > 50 OR COUNT(DISTINCT rp.PostId) >= 5;
