WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CO.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CO ON P.Id = CO.PostId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount
    FROM 
        UserActivity
    WHERE 
        Reputation > (SELECT AVG(Reputation) FROM Users)
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        HighReputationUsers
)
SELECT 
    UR.Rank,
    UR.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.CommentCount,
    UR.UpVotes,
    UR.DownVotes,
    UR.BadgeCount
FROM 
    UserRankings UR
WHERE 
    UR.Rank <= 10
ORDER BY 
    UR.Rank;
