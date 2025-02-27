WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes, 
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserActivity
    WHERE Reputation > 1000
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.UpVotes,
    U.DownVotes,
    U.BadgeCount,
    RANK() OVER (ORDER BY U.Reputation DESC) AS RankByReputation,
    RANK() OVER (ORDER BY U.PostCount DESC) AS RankByPosts,
    RANK() OVER (ORDER BY U.CommentCount DESC) AS RankByComments
FROM TopUsers U
JOIN (SELECT DISTINCT PostTypeId, COUNT(Id) AS PostTypeCount FROM Posts GROUP BY PostTypeId) PT ON PT.PostTypeCount > 50
ORDER BY U.Reputation DESC, U.PostCount DESC, U.CommentCount DESC
LIMIT 10;
