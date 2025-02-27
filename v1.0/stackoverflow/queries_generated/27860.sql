WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViews
    FROM
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
),
TopActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS ContributionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id
    ORDER BY 
        ContributionCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        U.DisplayName AS EditorDisplayName,
        PH.Comment
    FROM 
        PostHistory PH
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate > NOW() - INTERVAL '30 days'
)

SELECT 
    T.TagName,
    COALESCE(S.PostCount, 0) AS PostCount,
    COALESCE(S.TotalViews, 0) AS TotalViews,
    COALESCE(S.TotalScore, 0) AS TotalScore,
    COALESCE(S.AvgScore, 0) AS AvgScore,
    COALESCE(S.AvgViews, 0) AS AvgViews,
    U.DisplayName AS TopActiveUser,
    U.ContributionCount,
    U.TotalViews AS UserTotalViews,
    PH.EditorDisplayName,
    PH.CreationDate AS RecentEditDate,
    PH.Comment
FROM 
    TagStats S
FULL OUTER JOIN 
    TopActiveUsers U ON S.TagName IS NOT NULL
FULL OUTER JOIN 
    RecentPostHistory PH ON PH.PostId IS NOT NULL
ORDER BY 
    S.PostCount DESC NULLS LAST, U.ContributionCount DESC NULLS LAST, PH.CreationDate DESC NULLS LAST;
