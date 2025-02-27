WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(distinct P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN B.Date IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(CAST(P.AcceptedAnswerId IS NOT NULL AS INT), 0) AS HasAcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    GROUP BY 
        T.TagName
)
SELECT 
    A.UserDisplayName,
    A.PostCount,
    A.Upvotes - A.Downvotes AS NetVotes,
    P.Title AS TopViewedPost,
    P.ViewCount AS TopPostViewCount,
    T.TagName,
    T.TotalViews,
    T.AvgViews
FROM 
    UserActivity A
LEFT JOIN 
    PostStats P ON A.PostCount > 0 AND P.RankByViews = 1
LEFT JOIN 
    TagStatistics T ON T.PostsWithTag > 5
WHERE 
    A.BadgeCount > 3 OR (A.Upvotes > 10 AND A.Downvotes < 5)
ORDER BY 
    A.NetVotes DESC, 
    T.TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
