
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY P.Id, P.Title, P.ViewCount, P.CreationDate, P.AcceptedAnswerId
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        GROUP_CONCAT(T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN (SELECT TRIM(TRAILING '>' FROM TRIM(LEADING '<' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<', -1), '>', 1))) AS TagName) AS TagArray ON TRUE
    LEFT JOIN Tags T ON T.TagName = TagArray.TagName
    GROUP BY P.Id
),
PostSummary AS (
    SELECT 
        AP.PostId,
        AP.Title,
        AP.ViewCount,
        AP.CreationDate,
        AP.HasAcceptedAnswer,
        PT.Tags,
        R.UserRank
    FROM ActivePosts AP
    JOIN RankedUsers R ON AP.HasAcceptedAnswer = R.Id 
    LEFT JOIN PostTags PT ON AP.PostId = PT.PostId
)
SELECT 
    PS.Title,
    PS.ViewCount,
    PS.CreationDate,
    PS.HasAcceptedAnswer,
    COALESCE(PS.Tags, 'No Tags') AS Tags,
    U.DisplayName,
    CASE 
        WHEN PS.UserRank IS NOT NULL THEN 'Active User'
        ELSE 'Inactive User' 
    END AS UserStatus
FROM PostSummary PS
LEFT JOIN Users U ON U.Id = PS.HasAcceptedAnswer
WHERE PS.ViewCount > 100
  AND (PS.CreationDate < NOW() - INTERVAL 3 MONTH OR U.Id IS NULL)
ORDER BY PS.CreationDate DESC
LIMIT 50;
