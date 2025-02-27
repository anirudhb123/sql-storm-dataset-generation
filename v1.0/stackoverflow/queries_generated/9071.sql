WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 2 THEN 1 ELSE 0 END) AS EditCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON PH.UserId = U.Id
    WHERE 
        U.CreationDate >= '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostAssociatedCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS TotalVotes,
        MAX(P.LastActivityDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.CloseCount,
    UA.EditCount,
    UA.AvgScore,
    TS.TagName,
    TS.PostAssociatedCount AS TagsAssociatedWithPostCount,
    TS.TotalViews AS TotalTagViews,
    TS.AvgPostScore AS AvgTagPostScore,
    PE.Title AS PostTitle,
    PE.TotalComments,
    PE.TotalVotes,
    PE.LastActivity
FROM 
    UserActivity UA
JOIN 
    TagStatistics TS ON UA.PostCount > 5  -- Filtering users with more than 5 posts
JOIN 
    PostEngagement PE ON PE.LastActivity > CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    UA.PostCount DESC, UA.AvgScore DESC, PE.TotalVotes DESC;
