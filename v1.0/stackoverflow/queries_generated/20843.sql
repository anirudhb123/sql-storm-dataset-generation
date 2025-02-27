WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(COALESCE(U.UpVotes, 0) - COALESCE(U.DownVotes, 0)) AS NetVotes
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC NULLS LAST) AS RankPerUser
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only questions
    AND P.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseVoteCount,
        MAX(PH.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    U.NetVotes,
    TP.Title, 
    TP.Score,
    COALESCE(CPH.CloseVoteCount, 0) AS TotalCloseVotes,
    CPH.LastCloseDate,
    CPH.CloseReasons
FROM UserBadges UB
INNER JOIN Users U ON UB.UserId = U.Id
LEFT JOIN TopPosts TP ON U.Id = (
    SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId LIMIT 1
)
LEFT JOIN ClosedPostHistory CPH ON TP.PostId = CPH.PostId
WHERE U.Reputation > (
    SELECT AVG(Reputation) FROM Users
) 
AND U.CreationDate <= (
    SELECT MAX(CreationDate) FROM Users WHERE Reputation < U.Reputation
)
ORDER BY U.NetVotes DESC, UB.GoldBadges DESC, TP.Score DESC;
