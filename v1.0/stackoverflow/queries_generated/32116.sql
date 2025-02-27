WITH RecursivePostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.PostHistoryTypeId,
        1 AS RecursionLevel
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (1, 4, 10) -- Only consider initial titles, edits, or closure for recursion
    UNION ALL
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.PostHistoryTypeId,
        RP.RecursionLevel + 1
    FROM 
        PostHistory PH
    INNER JOIN 
        RecursivePostHistory RP ON PH.PostId = RP.PostId
    WHERE 
        PH.CreationDate > RP.CreationDate -- Continue tracing history
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS OriginalCreationDate,
    P.LastActivityDate,
    COALESCE(PH.EditCount, 0) AS EditCount,
    COALESCE(CT.ClosureCount, 0) AS ClosureCount,
    U.DisplayName AS LastEditedBy,
    RPH.UserDisplayName AS LastActionBy,
    RPH.CreationDate AS LastActionDate,
    CASE 
        WHEN PH.EditCount > 5 THEN 'Frequent Editor'
        ELSE 'Occasional Editor'
    END AS EditBehavior,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM 
    Posts P
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 6) -- Edits
    GROUP BY 
        PostId
) PH ON P.Id = PH.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS ClosureCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        PostId
) CT ON P.Id = CT.PostId
JOIN Users U ON P.LastEditorUserId = U.Id
JOIN RecursivePostHistory RPH ON P.Id = RPH.PostId
LEFT JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for last year
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.LastActivityDate, U.DisplayName, RPH.UserDisplayName, RPH.CreationDate, PH.EditCount, CT.ClosureCount
ORDER BY 
    P.LastActivityDate DESC, EditCount DESC;
