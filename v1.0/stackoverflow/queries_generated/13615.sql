SELECT 
    PH.PostId,
    PH.PostHistoryTypeId,
    PH.CreationDate,
    U.DisplayName AS UserDisplayName,
    PH.Comment,
    PH.Text AS ChangeDescription
FROM 
    PostHistory PH
JOIN 
    Users U ON PH.UserId = U.Id
WHERE 
    PH.CreationDate >= '2023-01-01' -- Adjust the date for your benchmarking needs
ORDER BY 
    PH.CreationDate DESC
LIMIT 1000; -- Adjust the limit for your benchmarking needs
