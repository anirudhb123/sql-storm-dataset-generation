-- Performance benchmarking SQL query

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
PostHistoryStatistics AS (
    SELECT 
        P.Id AS PostId,
        COUNT(H.Id) AS HistoryCount,
        MAX(H.CreationDate) AS LastEditDate,
        MAX(H.UserId) AS LastEditedBy
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    GROUP BY 
        P.Id
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalScore,
    U.TotalComments,
    T.TagName,
    T.PostsWithTag,
    T.TotalViews,
    T.AverageScore,
    PH.PostId,
    PH.HistoryCount,
    PH.LastEditDate,
    PH.LastEditedBy
FROM 
    UserStatistics U
CROSS JOIN 
    TagStatistics T
JOIN 
    PostHistoryStatistics PH ON PH.PostId = (
        SELECT 
            Id 
        FROM 
            Posts 
        ORDER BY 
            CreationDate DESC 
        LIMIT 1
    )
ORDER BY 
    U.Reputation DESC, T.PostsWithTag DESC;
