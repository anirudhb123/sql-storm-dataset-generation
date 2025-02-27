WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostsWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN LATERAL unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName ON TRUE
    LEFT JOIN Tags T ON T.TagName = TagName
    GROUP BY P.Id
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentChangeRank
    FROM PostHistory PH
    WHERE PH.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 11) AS ReopenCount
    FROM RecentPostHistory PH
    GROUP BY PH.PostId
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges B
    GROUP BY B.UserId
)

SELECT 
    UR.UserId,
    UR.Reputation,
    UR.ReputationRank,
    PP.PostId,
    PP.Title,
    PP.CreationDate AS PostCreationDate,
    PP.ViewCount,
    COALESCE(CPS.CloseCount, 0) AS CloseCount,
    COALESCE(CPS.ReopenCount, 0) AS ReopenCount,
    UPS.BadgeCount,
    UPS.GoldCount,
    UPS.SilverCount,
    UPS.BronzeCount,
    PP.Tags
FROM UserReputation UR
LEFT JOIN PostsWithTags PP ON PP.OwnerUserId = UR.UserId
LEFT JOIN ClosedPostStats CPS ON CPS.PostId = PP.PostId
LEFT JOIN UserBadgeStats UPS ON UPS.UserId = UR.UserId
WHERE 
    UR.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
    AND (CPS.CloseCount > 0 OR CPS.ReopenCount > 0)
ORDER BY UR.Reputation DESC, PP.ViewCount DESC
LIMIT 50;

-- Note: The query retrieves users above average reputation whose posts have been closed or reopened,
-- along with counts of their badges and the tags associated with their posts. 

