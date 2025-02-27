WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalViews, 
        TotalComments, 
        AcceptedAnswers,
        RANK() OVER (ORDER BY TotalViews DESC, PostCount DESC) AS ViewRank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
),
RecentChanges AS (
    SELECT 
        PH.UserId, 
        PH.CreationDate, 
        P.Title,
        P.Body,
        P.Tags,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentChangeRank
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13) AND 
        PH.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.PostCount,
    RU.TotalViews,
    RU.TotalComments,
    RU.AcceptedAnswers,
    RC.Title,
    RC.Body,
    RC.Tags,
    RC.CreationDate,
    CASE 
        WHEN RC.RecentChangeRank = 1 THEN 'Most Recent Change'
        ELSE 'Earlier Change'
    END AS ChangeStatus
FROM 
    RankedUsers RU
LEFT JOIN 
    RecentChanges RC ON RU.UserId = RC.UserId
WHERE 
    RU.ViewRank <= 10
ORDER BY 
    RU.TotalViews DESC,
    RU.PostCount DESC;
