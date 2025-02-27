WITH TopUsers AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, AVG(P.Score) AS AverageScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY U.Id, U.DisplayName, U.Reputation
    HAVING COUNT(P.Id) > 5 -- At least 5 posts
),
PopularTags AS (
    SELECT T.TagName, COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10 -- Only tags with more than 10 posts
),
RecentEdits AS (
    SELECT PH.UserId, PH.PostId, PH.CreationDate, P.Title, PH.Comment
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= NOW() - INTERVAL '30 days'
      AND PH.PostHistoryTypeId IN (4, 5) -- Title and Body edits
)
SELECT U.DisplayName AS Editor, U.Reputation AS EditorReputation, 
       T.TagName, T.PostCount, 
       R.PostId, R.Title, R.CreationDate AS EditDate, R.Comment
FROM TopUsers U
JOIN PopularTags T ON T.PostCount > 10
JOIN RecentEdits R ON R.UserId = U.UserId
ORDER BY U.Reputation DESC, T.PostCount DESC, R.EditDate DESC
LIMIT 50;
