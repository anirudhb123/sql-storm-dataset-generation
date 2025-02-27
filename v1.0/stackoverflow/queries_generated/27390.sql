WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
PostOverview AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        T.TagName,
        COALESCE(COUNT(C.Comment), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- BountyStart or BountyClose
    GROUP BY 
        P.Id, T.TagName
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.PopularPostCount,
    TS.AverageScore,
    TS.ActiveUsers,
    PO.PostId,
    PO.Title,
    PO.Body,
    PO.CreationDate,
    PO.CommentCount,
    PO.TotalBounty
FROM 
    TagStatistics TS
JOIN 
    PostOverview PO ON TS.TagName = PO.TagName
ORDER BY 
    TS.PostCount DESC, 
    PO.TotalBounty DESC
LIMIT 10;
