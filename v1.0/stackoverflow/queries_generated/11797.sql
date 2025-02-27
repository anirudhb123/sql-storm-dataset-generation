WITH Benchmark AS (
    SELECT 
        ph.PostHistoryTypeId,
        COUNT(*) AS ActionCount,
        MIN(ph.CreationDate) AS FirstActionDate,
        MAX(ph.CreationDate) AS LastActionDate,
        AVG(EXTRACT(EPOCH FROM (ph.CreationDate - LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate))) * 1000) AS AvgResponseTimeMs
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostHistoryTypeId
)

SELECT 
    ph.TypeName,
    b.ActionCount,
    b.FirstActionDate,
    b.LastActionDate,
    b.AvgResponseTimeMs
FROM 
    Benchmark b
JOIN 
    PostHistoryTypes ph ON b.PostHistoryTypeId = ph.Id
ORDER BY 
    b.ActionCount DESC;
