WITH RecursiveTagPaths AS (
    SELECT
        T.Id,
        T.TagName,
        T.Count,
        1 AS Level,
        CAST(T.TagName AS VARCHAR(MAX)) AS Path
    FROM Tags T
    WHERE T.IsModeratorOnly = 0  -- Starting with non-moderator tags

    UNION ALL

    SELECT
        T.Id,
        T.TagName,
        T.Count,
        RTP.Level + 1,
        CAST(RTP.Path + ' > ' + T.TagName AS VARCHAR(MAX))
    FROM Tags T
    JOIN RecursiveTagPaths RTP ON T.ExcerptPostId = RTP.Id -- Assuming excerpt links tags to related posts
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(P.ViewCount) AS TotalViews,
    SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    STRING_AGG(DISTINCT T.TagName, ', ') AS RelatedTags,
    RANK() OVER (PARTITION BY U.Id ORDER BY SUM(P.ViewCount) DESC) AS RankByViewCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN PostHistory PH ON P.Id = PH.PostId
LEFT JOIN PostLinks PL ON P.Id = PL.PostId
LEFT JOIN Tags T ON PL.RelatedPostId = T.WikiPostId
LEFT JOIN RecursiveTagPaths RTP ON RTP.Id = T.Id
WHERE 
    U.Reputation > 100 -- Filtering users with an appropriate reputation
    AND (P.CreationDate > NOW() - INTERVAL '1 YEAR' OR P.CreationDate IS NULL) -- Recent posts or NULL
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 5 -- Only users with more than 5 posts
ORDER BY TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

This query involves recursive CTEs for analyzing tag paths, aggregates user statistics filtered on reputation, counts their post actions with conditions on closure status, and utilizes window functions to rank users based on their total views. The output is constrained to users with a significant number of posts, ensuring the results are meaningful for benchmarking performance across various SQL constructs.
