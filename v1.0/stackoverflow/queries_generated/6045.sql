WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
        CommentCount,
        BadgeCount,
        RANK() OVER (ORDER BY (PostCount + CommentCount + BadgeCount) DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.Views,
    TU.UpVotes,
    TU.DownVotes,
    TU.PostCount,
    TU.CommentCount,
    TU.BadgeCount,
    TU.UserRank
FROM 
    TopUsers TU
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;
