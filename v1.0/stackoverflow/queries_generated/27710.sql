WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosures,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (6, 4, 8) THEN 1 ELSE 0 END) AS TotalEdits
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id
    GROUP BY 
        T.TagName
),
UserEngagement AS (
    SELECT 
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS PostsContributed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.DisplayName
),
EngagementSummary AS (
    SELECT 
        T.TagName,
        TS.TotalPosts,
        TS.TotalComments,
        TS.TotalClosures,
        TS.TotalEdits,
        U.DisplayName AS TopContributor,
        U.TotalViews,
        U.TotalUpVotes,
        U.TotalDownVotes
    FROM 
        TagStatistics TS
    LEFT JOIN 
        UserEngagement U ON U.PostsContributed = (SELECT MAX(PostsContributed) FROM UserEngagement)
)
SELECT 
    E.TagName,
    E.TotalPosts,
    E.TotalComments,
    E.TotalClosures,
    E.TotalEdits,
    E.TopContributor,
    E.TotalViews,
    E.TotalUpVotes,
    E.TotalDownVotes
FROM 
    EngagementSummary E
ORDER BY 
    E.TotalPosts DESC, E.TotalComments DESC;
