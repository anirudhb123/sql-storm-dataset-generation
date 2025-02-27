WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        NULL AS ParentId
    FROM Users U
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        UA.UserId
    FROM Users U
    JOIN Posts P ON P.OwnerUserId = U.Id
    JOIN UserActivity UA ON P.OwnerUserId = UA.UserId
    WHERE UA.UserId IS NOT NULL
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(COALESCE(V.Score, 0)) AS TotalVotes,
    COUNT(DISTINCT C.Id) AS TotalComments,
    MAX(P.LastActivityDate) AS LastPostActivity,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)  -- UpVotes and DownVotes
LEFT JOIN LATERAL (
    SELECT 
        T.TagName
    FROM 
        UNNEST(string_to_array(P.Tags, '>')) AS T(TagName)  -- Simulating tag extraction
) AS T ON TRUE
WHERE U.Reputation > 1000
GROUP BY U.Id
HAVING COUNT(DISTINCT P.Id) > 5
ORDER BY U.Reputation DESC
LIMIT 10;

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        RANK() OVER (ORDER BY SUM(V.Score) DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
)

SELECT
    PS.PostId,
    PS.Title,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    CASE 
        WHEN PS.UpVotes >= PS.DownVotes THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM PostStats PS
WHERE PS.PostRank <= 50
ORDER BY PS.UpVotes DESC;

SELECT 
    U.DisplayName,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    STRING_AGG(DISTINCT B.Name, ', ') AS Badges
FROM Users U
LEFT JOIN Badges B ON U.Id = B.UserId
WHERE B.Class = 1  -- Gold Badges
GROUP BY U.Id
ORDER BY BadgeCount DESC;

SELECT 
    P.Id,
    P.Title,
    P.CreationDate,
    JSONB_AGG(JSONB_BUILD_OBJECT('CommentId', C.Id, 'Text', C.Text)) AS Comments
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
WHERE P.CreationDate > NOW() - INTERVAL '30 days'
GROUP BY P.Id, P.Title, P.CreationDate
ORDER BY P.CreationDate DESC;

WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(P.Tags, '>')) AS TagName,
        COUNT(*) AS Frequency
    FROM Posts P
    GROUP BY TagName
)

SELECT 
    TF.TagName,
    TF.Frequency,
    CASE 
        WHEN TF.Frequency > 10 THEN 'Very Popular'
        WHEN TF.Frequency BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM TagFrequency TF
ORDER BY TF.Frequency DESC;

WITH PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEdited
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5)  -- Edit Title and Body
    GROUP BY PH.PostId
)

SELECT 
    P.Id,
    P.Title,
    P.CreationDate,
    COALESCE(PHS.EditCount, 0) AS TotalEdits,
    PHS.LastEdited
FROM Posts P
LEFT JOIN PostHistorySummary PHS ON P.Id = PHS.PostId
ORDER BY TotalEdits
