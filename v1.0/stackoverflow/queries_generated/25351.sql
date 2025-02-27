WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)::int) AS TotalUpvotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)::int) AS TotalDownvotes,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT P.Title, '; ') AS RelatedPostTitles
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        T.TagName
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Only count title, body, and tag edits
    GROUP BY 
        PH.PostId
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalUpvotes,
    TS.TotalDownvotes,
    TS.AverageScore,
    PHC.EditCount,
    PHC.UniqueEditors,
    TS.RelatedPostTitles
FROM 
    TagStats TS
LEFT JOIN 
    PostHistoryCounts PHC ON PHC.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || TS.TagName || '%')
ORDER BY 
    TS.PostCount DESC, TS.TotalUpvotes DESC;
