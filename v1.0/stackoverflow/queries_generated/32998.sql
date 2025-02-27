WITH RecursiveCTE AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        PV.ViewCount,
        1 AS Level
    FROM 
        Posts P
    LEFT JOIN 
        Posts PV ON P.AcceptedAnswerId = PV.Id
    WHERE 
        P.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.ViewCount,
        CTE.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursiveCTE CTE ON P2.ParentId = CTE.Id
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
    COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalClosures,
    AVG(CTE.ViewCount) AS AvgViewCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    RecursiveCTE CTE ON P.Id = CTE.Id
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(P.Id) > 5 AND AVG(CTE.Level) < 3
ORDER BY 
    AvgViewCount DESC
LIMIT 10;
