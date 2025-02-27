-- Performance benchmarking query example

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,  -- Count of upvotes
        SUM(V.VoteTypeId = 3) AS DownVotes  -- Count of downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.UpVotes,
    U.DownVotes,
    (U.UpVotes - U.DownVotes) AS NetVotes  -- Net votes calculation
FROM 
    UserStats U
WHERE 
    U.PostCount > 0  -- Filter to only include users who have posted
ORDER BY 
    U.Reputation DESC, 
    U.NetVotes DESC;  -- Order by reputation and then net votes
