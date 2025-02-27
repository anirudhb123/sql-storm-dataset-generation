SELECT 
    PH.PostHistoryTypeId,
    P.Title,
    P.OwnerDisplayName,
    COUNT(*) AS RevisionCount,
    MIN(PH.CreationDate) AS FirstRevisionDate,
    MAX(PH.CreationDate) AS LastRevisionDate
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    PH.CreationDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    PH.PostHistoryTypeId, P.Title, P.OwnerDisplayName
ORDER BY 
    RevisionCount DESC;
