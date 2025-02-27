WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
), 
RecentPostEdits AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(R.LastPostDate, '1970-01-01'::timestamp) AS LastPostDate,
        R.TotalViews
    FROM Users U
    LEFT JOIN PostStatistics P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            MAX(CreationDate) AS LastPostDate,
            SUM(ViewCount) AS TotalViews
        FROM Posts
        GROUP BY OwnerUserId
    ) R ON U.Id = R.OwnerUserId
    WHERE U.Reputation > 0
), 
UserEngagement AS (
    SELECT 
        A.UserId,
        COUNT(CASE WHEN B.BadgeCount > 0 THEN 1 END) AS BadgeHolders,
        AVG(A.Reputation) AS AvgReputation,
        SUM(A.TotalViews) AS SumViews
    FROM ActiveUsers A
    LEFT JOIN UserBadgeCounts B ON A.UserId = B.UserId
    GROUP BY A.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(SUM(PC.PostCount), 0) AS PostsCreated,
    COALESCE(SUM(RPV.TotalViews), 0) AS TotalPostViews,
    AVG(UE.AvgReputation) AS AverageEngagementReputation,
    MAX(RE.UserDisplayName) AS LastEditor,
    COUNT(RE.PostId) AS TotalEdits,
    SUM(CASE WHEN RE.Comment IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade
FROM Users U
LEFT JOIN UserBadgeCounts B ON U.Id = B.UserId
LEFT JOIN PostStatistics PC ON U.Id = PC.OwnerUserId
LEFT JOIN RecentPostEdits RE ON RE.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
LEFT JOIN UserEngagement UE ON U.Id = UE.UserId
WHERE U.CreationDate < NOW() - INTERVAL '1 year' 
GROUP BY U.Id, U.DisplayName, U.Reputation
HAVING AVG(UE.AvgReputation) > 100 AND SUM(RPV.TotalViews) IS NOT NULL
ORDER BY TotalBadges DESC, Reputation DESC;
