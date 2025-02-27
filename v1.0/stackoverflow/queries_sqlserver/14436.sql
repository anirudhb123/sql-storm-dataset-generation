
SELECT 
    PH.PostId,
    COUNT(*) AS RevisionCount,
    MIN(PH.CreationDate) AS FirstRevisionDate,
    MAX(PH.CreationDate) AS LastRevisionDate,
    MAX(PH.UserDisplayName) AS LastEditedBy
FROM 
    PostHistory AS PH
GROUP BY 
    PH.PostId
ORDER BY 
    RevisionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
