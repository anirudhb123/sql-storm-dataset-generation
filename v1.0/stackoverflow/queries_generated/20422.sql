WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation < 1000 THEN 'Low'
            WHEN Reputation BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS ReputationCategory
    FROM Users
),
PostSummaries AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes V
            WHERE V.PostId = P.Id AND V.VoteTypeId = 2
        ), 0) AS UpVotes,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes V
            WHERE V.PostId = P.Id AND V.VoteTypeId = 3
        ), 0) AS DownVotes,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0 
        END AS HasAcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
FlaggedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.Comment,
        PH.CreationDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Filter for Post Closed and Reopened
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.PostId) AS Popularity
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(PT.PostId) > 50
),
FinalResults AS (
    SELECT 
        U.DisplayName AS UserName,
        U.ReputationCategory,
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.HasAcceptedAnswer,
        COALESCE(FL.Comment, 'No comments') AS FlagComment,
        COALESCE(FL.CreationDate, NULL) AS FlagDate,
        IFNULL(PT.TagName, 'No tag') AS RelatedTag
    FROM UserReputation U
    JOIN PostSummaries PS ON PS.PostId = U.Id
    LEFT JOIN FlaggedPosts FL ON FL.PostId = PS.PostId
    LEFT JOIN PopularTags PT ON PT.Popularity > 100
    WHERE U.Reputation > 999
)

SELECT *
FROM FinalResults
WHERE (PostRank <= 5 OR HasAcceptedAnswer = 1)
ORDER BY UserName, ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
