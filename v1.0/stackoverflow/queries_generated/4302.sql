WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate
    FROM Users
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users)
), RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.ViewCount, P.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
), PostVoteSummary AS (
    SELECT V.PostId, COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
), PostHistoryCounts AS (
    SELECT PH.PostId, COUNT(*) AS EditCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY PH.PostId
), UserBadges AS (
    SELECT B.UserId, COUNT(*) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
)

SELECT U.Id AS UserId, U.DisplayName, U.Reputation,
       COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
       COALESCE(RP.ViewCount, 0) AS RecentPostViewCount,
       COALESCE(PVS.UpVotes, 0) AS TotalUpVotes,
       COALESCE(PVS.DownVotes, 0) AS TotalDownVotes,
       COALESCE(PHC.EditCount, 0) AS TotalEdits,
       COALESCE(UB.BadgeCount, 0) AS TotalBadges
FROM UserReputation U
LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RN = 1
LEFT JOIN PostVoteSummary PVS ON RP.Id = PVS.PostId
LEFT JOIN PostHistoryCounts PHC ON RP.Id = PHC.PostId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
ORDER BY U.Reputation DESC, RecentPostViewCount DESC;
