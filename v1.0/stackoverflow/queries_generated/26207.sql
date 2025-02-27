WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(*) AS TagCount
    FROM 
        Posts P
    CROSS JOIN 
        LATERAL string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><') AS Tag
    GROUP BY 
        P.Id
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(distinct P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        P.Title,
        P.Body,
        PH.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ARRAY_AGG(DISTINCT PHT.Name ORDER BY PH.CreationDate) AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, P.Title, P.Body, PH.CreationDate, P.ViewCount, P.AnswerCount, P.CommentCount
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalViews,
    PTC.TagCount,
    PHD.Title,
    PHD.Body,
    PHD.ViewCount,
    PHD.AnswerCount,
    PHD.CommentCount,
    PHD.HistoryTypes
FROM 
    ActiveUsers U
JOIN 
    PostTagCounts PTC ON U.PostCount > 0
JOIN 
    PostHistoryDetails PHD ON PHD.PostId IN (
      SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId
    )
ORDER BY 
    U.Reputation DESC, 
    PTC.TagCount DESC, 
    PHD.ViewCount DESC;
