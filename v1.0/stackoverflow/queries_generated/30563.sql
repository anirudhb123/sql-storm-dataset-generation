WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        P.PostTypeId,
        P.Score,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.OwnerUserId,
        P2.ParentId,
        P2.PostTypeId,
        P2.Score,
        R.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy R ON P2.ParentId = R.PostId
)

SELECT 
    U.DisplayName AS Owner,
    COUNT(P.Id) AS TotalPosts,
    SUM(P.Score) AS TotalScore,
    AVG(P.ViewCount) AS AverageViewCount,
    MAX(P.CreationDate) AS LastPostDate,
    ARRAY_AGG(T.TagName) AS Tags,
    STRING_AGG(B.Name, ', ') AS Badges,
    COALESCE(MAX(PH.Comment), 'No close reason') AS LastCloseReason
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Tags T ON T.Id = ANY (STRING_TO_ARRAY(P.Tags, ',')::int[])
LEFT JOIN 
    Badges B ON B.UserId = U.Id
LEFT JOIN 
    PostHistory PH ON PH.UserId = U.Id AND PH.PostId = P.Id AND PH.PostHistoryTypeId = 10 -- Close reason
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id
HAVING 
    COUNT(P.Id) > 10
ORDER BY 
    TotalScore DESC, LastPostDate DESC
LIMIT 50;
