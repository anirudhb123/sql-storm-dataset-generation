WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('<', T.TagName, '>')
    GROUP BY 
        T.TagName
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT B.Id) AS BadgesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT PH.Comment, ', ') AS EditComments,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.AverageScore,
    TS.AverageViews,
    TS.LastPostDate,
    US.UserId,
    US.DisplayName,
    US.PostsCreated,
    US.TotalScore,
    US.BadgesCount,
    PHD.EditCount,
    PHD.EditComments,
    PHD.LastEditDate
FROM 
    TagStats TS
JOIN 
    UserStats US ON US.PostsCreated > 0
JOIN 
    PostHistoryDetails PHD ON PHD.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%<', TS.TagName, '>'))
ORDER BY 
    TS.PostCount DESC, 
    US.TotalScore DESC;
