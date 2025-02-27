
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT C.Id) AS TotalComments,
        GROUP_CONCAT(DISTINCT U.DisplayName SEPARATOR ', ') AS TopContributors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.TagName
),
HistoryStats AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEdited,
        GROUP_CONCAT(DISTINCT PH.UserDisplayName SEPARATOR ', ') AS Editors
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        COALESCE(H.EditCount, 0) AS EditCount,
        H.LastEdited,
        H.Editors,
        ST.TagName,
        ST.TotalViews,
        ST.AverageScore,
        ST.TotalComments,
        ST.TopContributors
    FROM 
        Posts P
    LEFT JOIN 
        HistoryStats H ON P.Id = H.PostId
    JOIN 
        TagStats ST ON P.Tags LIKE CONCAT('%', ST.TagName, '%')
    WHERE 
        P.LastActivityDate > DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 30 DAY)
    ORDER BY 
        P.ViewCount DESC, 
        H.EditCount DESC
    LIMIT 10
)
SELECT 
    TP.Title,
    TP.ViewCount,
    TP.EditCount,
    TP.LastEdited,
    TP.Editors,
    TP.TagName,
    TP.TotalViews,
    TP.AverageScore,
    TP.TotalComments,
    TP.TopContributors
FROM 
    TopPosts TP
ORDER BY 
    TP.ViewCount DESC;
