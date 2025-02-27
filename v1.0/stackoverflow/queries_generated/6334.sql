WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        BadgeCount, 
        TotalBounty, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    UserRank,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    BadgeCount,
    TotalBounty,
    UpVotes,
    DownVotes
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
