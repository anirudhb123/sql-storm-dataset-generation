WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.OwnerUserId,
        P2.ViewCount,
        P2.CreationDate,
        RP.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostCTE RP ON P2.ParentId = RP.PostId
    WHERE 
        P2.PostTypeId = 2 -- Answers
)

SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(P.ViewCount) AS TotalViews,
    AVG(P.Score) AS AveragePostScore,
    CASE 
        WHEN COUNT(DISTINCT B.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId 
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalViews DESC;

WITH BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    BS.BadgeCount,
    BS.BadgeNames,
    COALESCE(PV.TotalViews, 0) AS TotalPostViews
FROM 
    Users U
LEFT JOIN 
    BadgeSummary BS ON U.Id = BS.UserId
LEFT JOIN 
    (
        SELECT 
            P.OwnerUserId,
            SUM(P.ViewCount) AS TotalViews
        FROM 
            Posts P
        GROUP BY 
            P.OwnerUserId
    ) PV ON U.Id = PV.OwnerUserId
WHERE 
    U.LastAccessDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC;
