WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        COUNT(C.Comment) AS CommentCount,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS Rank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM UserReputation U
    WHERE U.TotalPosts > 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    TU.ReputationRank,
    CONCAT(TU.DisplayName, ' has ', TU.Reputation, ' reputation and posted about "', RP.Title, '" on ', TO_CHAR(RP.CreationDate, 'FMMonth FMDD, YYYY')) AS UserSummary
FROM TopUsers TU
JOIN RecentPosts RP ON TU.UserId = RP.Id
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, RP.CommentCount DESC
LIMIT 5;
