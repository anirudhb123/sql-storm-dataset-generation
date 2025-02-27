WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostsWithHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.PostHistoryTypeId,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS rn,
        CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 
                (SELECT 
                    CT.Name 
                 FROM CloseReasonTypes CT 
                 WHERE CT.Id = CAST(PH.Comment AS int)) 
            ELSE NULL 
        END AS CloseReason
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
),
TopUsers AS (
    SELECT 
        UserId,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(Posts.Id) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts ON U.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY U.Id
    HAVING COUNT(Posts.Id) > 0
)
SELECT 
    UB.DisplayName,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    P.Title,
    P.CreationDate,
    P.CloseReason,
    TU.PostCount,
    TU.TotalVotes,
    CASE 
        WHEN P.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM UserBadges UB
JOIN PostsWithHistory P ON UB.UserId = P.PostId
JOIN TopUsers TU ON UB.UserId = TU.UserId
WHERE 
    UB.BadgeCount > 5 OR 
    (UB.GoldBadges > 2 AND TU.PostCount > 10)
ORDER BY UB.BadgeCount DESC, TU.PostCount DESC;
