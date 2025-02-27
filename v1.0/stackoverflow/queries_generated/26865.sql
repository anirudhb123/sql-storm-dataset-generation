WITH UserInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS VoteCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 1000 -- Filter for users with high reputation
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.CommentCount,
        P.AnswerCount,
        COALESCE(PH.CreationDate, P.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) -- Track edit title and body
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName
    ) T ON TRUE
    WHERE P.CreationDate >= NOW() - INTERVAL '6 months' -- Recent posts
    GROUP BY P.Id
),

Ranking AS (
    SELECT 
        UI.UserId,
        UI.DisplayName,
        UI.Reputation,
        PS.TotalViews,
        PS.PostCount,
        RANK() OVER (ORDER BY (UI.VoteCount + UI.CommentCount + UI.BadgeCount) DESC) AS UserRank
    FROM UserInteractions UI
    JOIN PostStatistics PS ON PS.PostId IN (SELECT DISTINCT P.Id FROM Posts P WHERE P.OwnerUserId = UI.UserId)
)

SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.TotalViews,
    R.PostCount,
    R.UserRank,
    PS.Title,
    PS.LastEditDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.AnswerCount,
    PS.AssociatedTags
FROM Ranking R
JOIN PostStatistics PS ON PS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = R.UserId)
WHERE R.UserRank <= 10 -- Limit to top 10 engaged users
ORDER BY R.UserRank, PS.ViewCount DESC;
