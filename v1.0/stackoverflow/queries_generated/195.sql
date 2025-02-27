WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostTypesWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ST.Tags,
        P.PostTypeId,
        P.AcceptedAnswerId,
        COALESCE(PA.DisplayName, 'Not Accepted') AS AcceptedBy
    FROM Posts P
    LEFT JOIN LATERAL (
        SELECT 
            STRING_AGG(TRIM(value), ', ') AS Tags
        FROM UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS value
    ) ST ON TRUE
    LEFT JOIN Users PA ON P.AcceptedAnswerId = PA.Id
    WHERE P.PostTypeId IN (1, 2)
),
VoteSummary AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Votes
    GROUP BY PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.Tags,
    Vs.UpVoteCount,
    Vs.DownVoteCount
FROM UserStats U
JOIN PostTypesWithTags P ON U.TotalPosts > 0
LEFT JOIN VoteSummary Vs ON P.PostId = Vs.PostId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 50;

-- Selecting users with reputation above 1000, their posts, and associated vote statistics
-- utilizing CTEs, aggregates, strings, and outer joins to gather comprehensive data for performance benchmarking.
