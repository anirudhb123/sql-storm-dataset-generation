WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
HighScorePosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        T.TagName AS PrimaryTag
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN LATERAL (
        SELECT
            T.TagName
        FROM Tags T
        WHERE T.Id = ANY(STRING_TO_ARRAY(P.Tags, '>'::text)::int[])
        LIMIT 1
    ) AS T ON TRUE
    WHERE P.Score > 50
    ORDER BY P.CreationDate DESC
    LIMIT 5
)
SELECT
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.CommentCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    HSP.Title,
    HSP.ViewCount,
    HSP.Score,
    HSP.CreationDate,
    HSP.PrimaryTag
FROM UserStats US
JOIN HighScorePosts HSP ON US.UserId = HSP.OwnerDisplayName
ORDER BY US.Reputation DESC, HSP.Score DESC;
