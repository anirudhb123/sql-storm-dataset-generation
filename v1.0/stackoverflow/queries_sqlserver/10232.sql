
SELECT 
    PH.PostHistoryTypeId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS UserDisplayName,
    PH.CreationDate AS HistoryCreationDate,
    COUNT(*) AS ChangeCount
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
JOIN 
    Users U ON PH.UserId = U.Id
WHERE 
    PH.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH
GROUP BY 
    PH.PostHistoryTypeId, P.Title, P.CreationDate, U.DisplayName, PH.CreationDate
ORDER BY 
    ChangeCount DESC;
