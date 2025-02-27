-- Performance Benchmarking Query
WITH PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        STUFF((SELECT ',' + T.TagName
               FROM Tags T 
               WHERE P.Tags LIKE '%' + T.TagName + '%'
               FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Tags
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
PostTypeCount AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY PT.Name
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.Score,
    PA.ViewCount,
    PA.OwnerDisplayName,
    PA.CommentCount,
    PA.BadgeCount,
    PA.Tags,
    PT.PostType,
    PT.PostCount
FROM PostAnalytics PA
JOIN PostTypeCount PT ON PA.Tags LIKE '%' + PT.PostType + '%'
ORDER BY PA.Score DESC, PA.ViewCount DESC;
