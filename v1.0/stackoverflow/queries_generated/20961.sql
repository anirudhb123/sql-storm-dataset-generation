WITH TagUsage AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(U.Reputation, 0)) AS AvgReputation,
        CASE 
            WHEN SUM(COALESCE(P.ViewCount, 0)) >= 500 THEN 'High Engagement'
            WHEN SUM(COALESCE(P.ViewCount, 0)) BETWEEN 100 AND 499 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.Id, T.TagName
),

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(C.VoteTypeId) FILTER (WHERE C.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(COUNT(C.VoteTypeId) FILTER (WHERE C.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    LEFT JOIN 
        Votes C ON C.PostId = P.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),

RecentChanges AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.UserId,
        U.Reputation AS UserReputation,
        DENSE_RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory PH
    JOIN 
        Users U ON U.Id = PH.UserId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)  -- Closed, Reopened, Deleted, Undeleted
)

SELECT 
    TU.TagId,
    TU.TagName,
    TU.PostCount,
    TU.TotalViews,
    TU.AvgReputation,
    TU.EngagementLevel,
    PA.PostId, 
    PA.Title,
    PA.CreationDate,
    PA.UpvoteCount,
    PA.DownvoteCount,
    CASE 
        WHEN R.ChangeRank IS NOT NULL THEN 'Recent Changes Made'
        ELSE 'No Recent Changes'
    END AS ChangeStatus
FROM 
    TagUsage TU
LEFT JOIN 
    PostActivity PA ON PA.RowNum = 1  -- Use most recent post for each tag
LEFT JOIN 
    RecentChanges R ON R.PostId = PA.PostId
WHERE 
    TU.PostCount > 10  -- Consider only tags with significant usage
ORDER BY 
    TU.TotalViews DESC, 
    TU.EngagementLevel;
