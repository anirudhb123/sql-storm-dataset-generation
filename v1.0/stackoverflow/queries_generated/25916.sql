WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000  -- Focus on users with high reputation
    GROUP BY U.Id
),
TopTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(DISTINCT P.Id) > 5  -- Only consider tags with more than 5 posts
    ORDER BY TotalViews DESC
    LIMIT 10  -- Get top 10 tags by view count
),
PostStatistics AS (
    SELECT 
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        C.Name AS CloseReason,
        PH.CreationDate AS LastEditDate,
        U.DisplayName AS LastEditor
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)  -- Only consider title, body, and tags edits
    LEFT JOIN CloseReasonTypes C ON P.Id = C.Id
    LEFT JOIN Users U ON P.LastEditorUserId = U.Id
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'  -- Only consider posts created in the last year
)
SELECT 
    UR.DisplayName AS User,
    UR.Reputation,
    UR.BadgeCount,
    UR.TotalBounty,
    TT.TagName,
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.CloseReason,
    PS.LastEditDate,
    PS.LastEditor
FROM UserReputation UR
JOIN TopTags TT ON TT.TagName IN (SELECT UNNEST(STRING_TO_ARRAY((SELECT STRING_AGG(T.TagName, ',') FROM Tags T WHERE T.Count > 100), ',')))  -- Connect based on tags with significant presence
JOIN PostStatistics PS ON PS.Title LIKE '%' || TT.TagName || '%'  -- Filter posts that relate to these top tags
ORDER BY UR.Reputation DESC, PS.ViewCount DESC;

