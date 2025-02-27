WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes, -- Upvotes
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes -- Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    WHERE U.Reputation > 100 -- Filter for users with reputation greater than 100
    GROUP BY U.Id, U.DisplayName, U.Reputation
), RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        COUNT(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 END) OVER (PARTITION BY P.OwnerUserId) AS AcceptedAnswers
    FROM Posts P
), RecentPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.PostRank,
        UA.DisplayName,
        UA.Reputation
    FROM RankedPosts RP
    JOIN UserActivity UA ON UA.UserId = RP.OwnerUserId
    WHERE RP.PostRank <= 3 -- Get up to 3 latest posts for each user
)
SELECT 
    RP.*,
    COUNT(DISTINCT PH.Id) AS HistoryCount,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', PH.CreationDate::date, PHT.Name), '; ') AS HistoryLog
FROM RecentPosts RP
LEFT JOIN PostHistory PH ON PH.PostId = RP.PostId
LEFT JOIN PostHistoryTypes PHT ON PHT.Id = PH.PostHistoryTypeId
WHERE RP.Reputation BETWEEN 200 AND 1000 -- Filter specific user reputation ranges
GROUP BY RP.PostId, RP.Title, RP.PostRank, RP.DisplayName, RP.Reputation
HAVING COUNT(DISTINCT PH.Id) > 0 -- Only include posts that have history
ORDER BY RP.Reputation DESC, RP.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination for user interface
This query uses Common Table Expressions (CTEs) to rank users based on activity, count their recent posts, and generates a history log of changes for those posts while also employing window functions for aggregation and filtering. The use of `STRING_AGG` allows for a compact history representation concerning each post, while the creative filtering and joining showcase SQL capabilities amidst the provided schema.
