WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 -- Considering only Questions
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        string_agg(trim(unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))), ', ') AS Tags
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
)
SELECT 
    UA.DisplayName AS UserName,
    UA.TotalPosts,
    UA.Questions,
    UA.Answers,
    UA.Wikis,
    UA.UpVotes,
    UA.DownVotes,
    UA.TotalComments,
    TP.PostId,
    TP.Title,
    TP.Body,
    TP.Score,
    TP.CreationDate,
    PT.Tags
FROM UserActivity UA
LEFT JOIN TopPosts TP ON UA.UserId = TP.OwnerUserId AND TP.Rank = 1
LEFT JOIN PostTags PT ON TP.PostId = PT.PostId
ORDER BY UA.TotalPosts DESC, UA.UpVotes DESC
LIMIT 10;
