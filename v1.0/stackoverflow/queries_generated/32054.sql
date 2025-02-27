WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        CAST(DisplayName AS VARCHAR(200)) AS FullPath
    FROM Users
    WHERE Reputation > 1000  -- Starting with users having more than 1000 reputation

    UNION ALL

    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        CAST(UH.FullPath || ' -> ' || U.DisplayName AS VARCHAR(200))
    FROM Users U
    JOIN UserHierarchy UH ON U.Id = UH.Id + 1  -- Assuming a simple hierarchy (this can also be based on some other criteria)
    WHERE U.Reputation > 500  -- Moving downward in reputation within certain constraints
),

TopPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS RowNum
    FROM Posts P
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        U.DisplayName AS OwnerName,
        P.Title,
        P.Body,
        T.TagName,
        PH.CreationDate AS HistoryDate,
        PH.Comment
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5)  -- Edited Title and Body
)

SELECT 
    UH.FullPath AS UserPath,
    P.Title AS PostTitle,
    P.ViewCount,
    P.LastActivityDate,
    COALESCE(T.TagName, 'No Tags') AS PostTag,
    CONCAT(U.DisplayName, ' (', U.Reputation, ' Rep)') AS UserReputation
FROM UserHierarchy UH
JOIN TopPosts P ON UH.Id = P.PostId
LEFT JOIN Tags T ON P.PostId = T.Id
LEFT JOIN PostDetails PD ON P.PostId = PD.PostId
WHERE UH.Reputation >= 1500 
ORDER BY P.ViewCount DESC
LIMIT 10
OFFSET 5;  -- Skip the first 5 entries for pagination
