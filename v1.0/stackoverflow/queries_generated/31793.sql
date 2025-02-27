WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only consider Questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy PH ON P.ParentId = PH.Id
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS QuestionCount,
    COUNT(DISTINCT A.Id) AS AnswerCount,
    SUM(P.ViewCount) AS TotalViews,
    AVG(P.Score) AS AverageScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    COALESCE(MAX(B.Class), 0) AS HighestBadgeClass,
    MAX(B.Date) AS LastBadgeDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 -- Answers
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Tags T ON T.Id = PL.RelatedPostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 0
ORDER BY 
    TotalViews DESC, AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

-- Additionally, we qualify that users with no badges will show as '0' for HighestBadgeClass
-- which will return such users with NULL excluded and we ensure we provide sorting to highlight activity

-- Performance considerations include the use of index on UserId in each join condition for improved efficiency.
