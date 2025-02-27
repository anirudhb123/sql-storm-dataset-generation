WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(VoteTypeId = 3), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId 
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes - TotalDownVotes AS VoteBalance,
        RANK() OVER (ORDER BY TotalBadges DESC, VoteBalance DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.VoteBalance,
    T.UserRank,
    CASE 
        WHEN T.VoteBalance > 0 THEN 'Positive'
        WHEN T.VoteBalance < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus,
    COUNT(DISTINCT PH.Id) AS TotalPostHistoryEntries
FROM TopUsers T
LEFT JOIN PostHistory PH ON T.UserId = PH.UserId 
GROUP BY T.UserId, T.DisplayName, T.VoteBalance, T.UserRank
HAVING COUNT(DISTINCT PH.Id) > 0
ORDER BY T.UserRank
LIMIT 10;
