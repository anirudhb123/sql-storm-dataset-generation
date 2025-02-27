SELECT 
    PH.PostHistoryTypeId,
    COUNT(*) AS TotalChanges,
    MIN(PH.CreationDate) AS FirstChangeDate,
    MAX(PH.CreationDate) AS LastChangeDate,
    AVG(EXTRACT(EPOCH FROM (PH.CreationDate - LAG(PH.CreationDate) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate))) / 60) AS AvgTimeBetweenChanges
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    PH.PostHistoryTypeId
ORDER BY 
    TotalChanges DESC;
