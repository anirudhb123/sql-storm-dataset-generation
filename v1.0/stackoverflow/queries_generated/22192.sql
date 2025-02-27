WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
    WHERE Reputation IS NOT NULL
),

PostStats AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.ANSWER_COUNT,
           COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
           COALESCE(V.DownVoteCount, 0) AS DownVoteCount,
           P.ViewCount,
           P.Tags,
           PU.Reputation AS OwnerReputation,
           PU.DisplayName AS OwnerDisplayName,
           PM.LastEditDate
    FROM Posts P
    LEFT JOIN (
        SELECT PostId,
               COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
               COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Users PU ON P.OwnerUserId = PU.Id
    LEFT JOIN LATERAL (
        SELECT MAX(LastEditDate) AS LastEditDate
        FROM Posts AS InnerP
        WHERE InnerP.Id = P.Id
        GROUP BY InnerP.Id
    ) PM ON TRUE
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),

UserBadges AS (
    SELECT UserId,
           COUNT(*) FILTER (WHERE Class = 1) AS GoldBadgeCount,
           COUNT(*) FILTER (WHERE Class = 2) AS SilverBadgeCount,
           COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadgeCount
    FROM Badges
    GROUP BY UserId
),

PopularPosts AS (
    SELECT PS.*,
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS CommentCount,
           (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = PS.PostId AND PH.PostHistoryTypeId = 10) AS ClosedCount
    FROM PostStats PS
    WHERE PS.ViewCount > 1000
)

SELECT U.Id AS UserId,
       U.DisplayName AS UserName,
       COALESCE(UB.GoldBadgeCount, 0) AS GoldBadges,
       COALESCE(UB.SilverBadgeCount, 0) AS SilverBadges,
       COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadges,
       PP.PostId,
       PP.Title,
       PP.UpVoteCount,
       PP.DownVoteCount,
       PP.CommentCount,
       PP.ClosedCount,
       PP.CreationDate,
       PP.OwnerReputation
FROM UserReputation U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
WHERE U.ReputationRank <= 100
ORDER BY U.Reputation DESC, PP.UpVoteCount DESC NULLS LAST;
