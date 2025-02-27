SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    PC.Comment AS PostComment,
    PH.CreationDate AS HistoryDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments PC ON P.Id = PC.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1  -- Filtering for questions
ORDER BY 
    PH.CreationDate DESC
LIMIT 10; 
