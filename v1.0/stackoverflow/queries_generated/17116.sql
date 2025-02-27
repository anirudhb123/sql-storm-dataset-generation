SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.CreationDate AS HistoryCreationDate,
    PHT.Name AS PostHistoryType
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Looking for questions only
ORDER BY 
    PH.CreationDate DESC
LIMIT 10; -- Limit to most recent 10 history entries
