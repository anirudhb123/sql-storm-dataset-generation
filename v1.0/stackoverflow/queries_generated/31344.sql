WITH RecursivePostHierarchy AS (
    -- Base case: Select all questions
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        CAST(0 AS INT) AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions

    UNION ALL

    -- Recursive case: Select answers related to the questions
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        R.Depth + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
)

-- Main query to benchmark performance
SELECT 
    U.DisplayName AS Author,
    COUNT(DISTINCT RPH.PostId) AS TotalPosts,
    SUM(COALESCE(PH.Comment IS NOT NULL, 0)) AS EditCount,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT C.Id) AS CommentCount,
    MAX(P.CreationDate) AS MostRecentPost,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    Users U ON RPH.OwnerUserId = U.Id
LEFT JOIN 
    Posts P ON RPH.PostId = P.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Tags T ON T.Id IN (SELECT unnest(string_to_array(P.Tags, '<>'))::int[]) -- Extract tag ids
WHERE 
    P.ViewCount > 100 -- Filtering posts with more than 100 views
GROUP BY 
    U.DisplayName
HAVING 
    SUM(U.Reputation) > 1000 -- Ensuring only high-reputation users
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 50; -- Limiting to top 50 users based on post counts
