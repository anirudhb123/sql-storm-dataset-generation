WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ARRAY_AGG(T.TagName) AS TagsList
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    LEFT JOIN 
        Tags T ON T.Id = ANY (string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[])
    WHERE 
        P.PostTypeId = 1 -- Filter for Questions only
    GROUP BY 
        P.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        Ph.PostId,
        MIN(Ph.CreationDate) AS ClosedDate,
        COUNT(Ph.Id) AS TotalCloseReasons
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        Ph.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Body,
    PS.OwnerDisplayName,
    PS.CreationDate,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.TagsList,
    COALESCE(CPS.ClosedDate, 'No Closure') AS FirstClosedDate,
    COALESCE(CPS.TotalCloseReasons, 0) AS ClosureCount
FROM 
    PostStats PS
LEFT JOIN 
    ClosedPostStats CPS ON PS.PostId = CPS.PostId
ORDER BY 
    PS.ViewCount DESC,
    PS.AnswerCount DESC
LIMIT 50;
