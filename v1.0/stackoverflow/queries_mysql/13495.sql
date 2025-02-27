
WITH UsersStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        (@row_number := @row_number + 1) AS Rank
    FROM 
        UsersStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    CommentCount,
    UpVotes,
    DownVotes
FROM 
    TopUsers
WHERE 
    Rank <= 10;
