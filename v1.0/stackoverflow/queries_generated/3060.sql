WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        RANK() OVER (ORDER BY Users.Reputation DESC) AS ReputationRank
    FROM Users
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
ActivePosts AS (
    SELECT 
        Posts.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Posts.Score) AS TotalScore,
        AVG(DATEDIFF(second, Posts.CreationDate, COALESCE(Posts.ClosedDate, GETDATE()))) AS AvgPostAge
    FROM Posts
    WHERE Posts.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY Posts.OwnerUserId
),
ReputationOverview AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(B.GoldBadges, 0) AS GoldBadges,
        COALESCE(B.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(P.AvgPostAge, 0) AS AvgPostAge,
        R.Reputation,
        R.ReputationRank
    FROM UserReputation R
    LEFT JOIN UserBadges B ON R.UserId = B.UserId
    LEFT JOIN ActivePosts P ON R.UserId = P.OwnerUserId
)
SELECT 
    R.DisplayName,
    R.BadgeCount,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    R.PostCount,
    R.TotalScore,
    R.AvgPostAge,
    R.Reputation,
    R.ReputationRank
FROM ReputationOverview R
WHERE (R.BadgeCount > 0 OR R.PostCount > 5) 
AND R.ReputationRank <= 50
ORDER BY R.Reputation DESC, R.TotalScore DESC;
