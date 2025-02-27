
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN 
                (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(ph.Comment AS UNSIGNED))
            ELSE 
                'Unknown Reason'
        END AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    cp.ClosedDate,
    cp.CloseReason,
    rp.PositiveComments
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5 OR cp.ClosedDate IS NOT NULL
ORDER BY 
    rp.Score DESC, cp.ClosedDate DESC;
