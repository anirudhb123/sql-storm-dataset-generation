-- Retrieve the top 10 most recent posts along with their user display names and post types
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    PT.Name AS PostType
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
