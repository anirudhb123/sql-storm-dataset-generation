WITH RECURSIVE UserReputationScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Location,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        0 AS Level
    FROM Users U
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation + COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 5) THEN 1 ELSE -1 END), 0) AS Reputation,
        U.CreationDate,
        U.Location,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        Level + 1
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    JOIN UserReputationScores UR ON UR.UserId = V.PostId
    WHERE Level < 10
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
    SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
    AVG(CASE WHEN P.LastActivityDate IS NOT NULL THEN DATEDIFF(CURRENT_TIMESTAMP, P.LastActivityDate) END) AS AvgDaysSinceLastActivity,
    STRING_AGG(DISTINCT T.TagName, ', ') AS UserTags
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN LATERAL (
    SELECT 
        TRIM(SUBSTRING(tag FROM 2 FOR LENGTH(tag) - 2)) AS TagName
    FROM unnest(string_to_array(P.Tags, '><')) as tag
) AS T ON TRUE
WHERE U.Reputation > 1000
GROUP BY U.DisplayName, U.Reputation
HAVING COUNT(DISTINCT P.Id) > 5
ORDER BY U.Reputation DESC
LIMIT 50
OFFSET 10;

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT P2.Id) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Posts P2 ON PL.RelatedPostId = P2.Id
    WHERE P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY P.Id
)

SELECT 
    PS.PostId,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.RelatedPostCount,
    CASE 
        WHEN PS.UpVoteCount > PS.DownVoteCount THEN 'Positive'
        ELSE 'Needs Attention'
    END AS PostStatus
FROM PostStats PS
WHERE PS.CommentCount > 0
ORDER BY PS.UpVoteCount DESC
LIMIT 100;
