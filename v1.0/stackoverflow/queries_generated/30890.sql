WITH RECURSIVE TagHierarchy AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count,
        T.ExcerptPostId,
        T.WikiPostId,
        1 AS Level
    FROM 
        Tags T
    WHERE 
        T.IsModeratorOnly = 0  -- Only consider non-moderator tags.

    UNION ALL

    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        T.ExcerptPostId,
        T.WikiPostId,
        TH.Level + 1
    FROM 
        Tags T
    JOIN 
        PostLinks PL ON PL.RelatedPostId = T.ExcerptPostId
    JOIN 
        TagHierarchy TH ON TH.TagId = T.WikiPostId
)
, UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(NULLIF(P.ViewCount, 0)) AS AvgViewCount -- Avoid division by zero.
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalScore,
    U.AvgViewCount,
    T.TagName,
    COUNT(DISTINCT PL.RelatedPostId) AS LinkedPostCount
FROM 
    UserStatistics U
LEFT JOIN 
    PostLinks PL ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PL.PostId) -- Links to User’s posts
LEFT JOIN 
    TagHierarchy T ON T.TagId IN (SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '><'))::int) FROM Posts P WHERE P.OwnerUserId = U.UserId) -- Tags for User’s posts
WHERE 
    U.TotalPosts > 10 AND 
    U.TotalScore > 1000 -- Filtering criteria
GROUP BY 
    U.UserId, U.DisplayName, T.TagName
HAVING 
    COUNT(DISTINCT PL.RelatedPostId) > 5 -- At least 5 linked posts for each user
ORDER BY 
    U.TotalScore DESC, 
    U.DisplayName ASC;
