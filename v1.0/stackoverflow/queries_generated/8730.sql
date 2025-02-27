WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.PostTypeId IN (1, 2) -- Considering Questions and Answers only
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        pht.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, HistoryCreationDate, pht.Name
),
AggregatedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.VoteCount,
        COALESCE(SUM(CASE WHEN ph.HistoryCount IS NOT NULL THEN ph.HistoryCount ELSE 0 END), 0) AS TotalHistories
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName, rp.VoteCount
)
SELECT 
    ar.PostId,
    ar.Title,
    ar.CreationDate,
    ar.Score,
    ar.ViewCount,
    ar.OwnerDisplayName,
    ar.VoteCount,
    ar.TotalHistories
FROM 
    AggregatedResults ar
ORDER BY 
    ar.Score DESC, ar.ViewCount DESC
LIMIT 100;
