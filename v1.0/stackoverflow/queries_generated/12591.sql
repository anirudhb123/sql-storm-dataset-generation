-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TotalPostsWithTag,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpvotes,
    U.TotalDownvotes,
    T.TagName,
    T.TotalPostsWithTag,
    T.TotalViews,
    T.AveragePostScore
FROM 
    UserStatistics U
LEFT JOIN 
    TagStatistics T ON U.TotalPosts > 0 
ORDER BY 
    U.Reputation DESC, 
    T.TotalViews DESC;
