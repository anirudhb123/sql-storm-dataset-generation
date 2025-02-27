-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.UpvotedPosts,
    U.DownvotedPosts,
    U.TotalViews,
    U.TotalComments,
    T.TagName,
    T.PostCount AS TagPostCount,
    PH.EditCount,
    PH.LastEditDate
FROM 
    UserStats U
LEFT JOIN 
    TagStats T ON U.PostCount > 0  -- Change this condition based on your goal
LEFT JOIN 
    PostHistoryStats PH ON PH.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId)
ORDER BY 
    U.TotalViews DESC, U.PostCount DESC;
