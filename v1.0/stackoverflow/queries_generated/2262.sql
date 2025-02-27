WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(C.Id) DESC) AS CommentRank
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(PS.TotalUpVotes), 0) AS TotalUserUpVotes,
        COALESCE(SUM(PS.TotalDownVotes), 0) AS TotalUserDownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)
SELECT 
    TU.Id,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalUserUpVotes,
    TU.TotalUserDownVotes,
    UV.VoteCount AS UserVoteCount,
    NVL(TU.UserRank, 'Unranked') AS UserRank,
    CASE 
        WHEN TU.TotalUserUpVotes > TU.TotalUserDownVotes THEN 'Positive'
        WHEN TU.TotalUserUpVotes < TU.TotalUserDownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopUsers TU
LEFT JOIN UserVotes UV ON TU.Id = UV.UserId
WHERE 
    TU.TotalUserUpVotes > 0 OR TU.TotalUserDownVotes > 0
ORDER BY 
    TU.TotalUserUpVotes DESC,
    TU.TotalUserDownVotes ASC;
