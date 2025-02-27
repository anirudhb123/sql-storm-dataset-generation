
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryCount AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        PH.PostId
),
DetailedPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PS.PostCount,
        PS.TotalViews,
        PS.AverageScore,
        U.TotalViews AS UserTotalViews,
        U.TotalScore AS UserTotalScore,
        PHC.EditCount
    FROM 
        Posts P
    JOIN 
        TagStats PS ON P.Tags LIKE '%' + PS.TagName + '%'
    JOIN 
        UserStats U ON P.OwnerUserId = U.UserId
    LEFT JOIN 
        PostHistoryCount PHC ON P.Id = PHC.PostId
    WHERE 
        P.PostTypeId = 1 
)
SELECT 
    D.Title,
    D.CreationDate,
    D.PostCount,
    D.TotalViews,
    D.AverageScore,
    D.UserTotalViews,
    D.UserTotalScore,
    COALESCE(D.EditCount, 0) AS EditCount
FROM 
    DetailedPostStats D
WHERE 
    D.TotalViews > 1000 
ORDER BY 
    D.TotalViews DESC, D.AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
