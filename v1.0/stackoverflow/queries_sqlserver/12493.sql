
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
    PH.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
GROUP BY 
    PH.PostHistoryTypeId, P.Title, P.OwnerDisplayName
ORDER BY 
    RevisionCount DESC;
