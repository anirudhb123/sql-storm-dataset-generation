
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT C.Id) AS TotalComments,
        LISTAGG(DISTINCT U.DisplayName, ', ') WITHIN GROUP (ORDER BY U.DisplayName) AS TopContributors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
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
        LISTAGG(DISTINCT PH.UserDisplayName, ', ') WITHIN GROUP (ORDER BY PH.UserDisplayName) AS Editors
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
        TagStats ST ON P.Tags LIKE '%' || ST.TagName || '%'
    WHERE 
        P.LastActivityDate > DATEADD(DAY, -30, '2024-10-01')
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
