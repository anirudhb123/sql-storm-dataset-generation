
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(V.BountyAmount, 0)) AS AvgBounty,
        @row_number:=@row_number + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    CROSS JOIN 
        (SELECT @row_number := 0) AS r
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Views, 
        UpVotes, 
        DownVotes, 
        PostCount, 
        Questions, 
        Answers, 
        AvgBounty,
        UserRank
    FROM 
        UserStats
    WHERE 
        UserRank <= 10
),
MostActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.LastActivityDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 30 DAY)
    GROUP BY 
        P.Id, P.Title, P.CreationDate
    HAVING 
        COUNT(C) > 0
    ORDER BY 
        UpVotes DESC
    LIMIT 5
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    U.PostCount,
    U.Questions,
    U.Answers,
    P.Title AS MostActivePost,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes
FROM 
    TopUsers U
JOIN 
    MostActivePosts P ON U.UserId = P.PostId 
ORDER BY 
    U.Reputation DESC, P.UpVotes DESC;
