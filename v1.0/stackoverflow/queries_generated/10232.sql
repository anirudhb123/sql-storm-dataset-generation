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
    PH.CreationDate >= NOW() - INTERVAL '1 month'
GROUP BY 
    PH.PostHistoryTypeId, P.Title, P.CreationDate, U.DisplayName, PH.CreationDate
ORDER BY 
    ChangeCount DESC;
