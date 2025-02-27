WITH RecursiveUserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        1 AS ActivityLevel,
        CAST(U.DisplayName AS VARCHAR(MAX)) AS ActivityPath
    FROM Users U
    WHERE U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        R.Id,
        R.DisplayName,
        R.Reputation,
        R.CreationDate,
        R.LastAccessDate,
        R.Views,
        R.UpVotes,
        R.DownVotes,
        RA.ActivityLevel + 1,
        CAST(RA.ActivityPath + ' -> ' + R.DisplayName AS VARCHAR(MAX))
    FROM Users R
    INNER JOIN RecursiveUserActivity RA ON R.Reputation > RA.Reputation
    WHERE RA.ActivityLevel < 5
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges B
    GROUP BY B.UserId
),
MostActiveTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 5
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
)
SELECT 
    UA.DisplayName AS UserName,
    UA.Reputation,
    UA.Views,
    COALESCE(UB.GoldCount, 0) AS GoldBadges,
    COALESCE(UB.SilverCount, 0) AS SilverBadges,
    COALESCE(UB.BronzeCount, 0) AS BronzeBadges,
    UGS.TotalPosts,
    UGS.TotalScore,
    UGS.AvgViewCount,
    STRING_AGG(MT.TagName, ', ') AS TopTags
FROM RecursiveUserActivity UA
LEFT JOIN UserBadges UB ON UA.Id = UB.UserId
LEFT JOIN UserPostStats UGS ON UA.Id = UGS.UserId
LEFT JOIN MostActiveTags MT ON MT.PostCount > 10
GROUP BY UA.DisplayName, UA.Reputation, UA.Views, UGS.TotalPosts, UGS.TotalScore, UGS.AvgViewCount
HAVING UA.Reputation BETWEEN 1000 AND 5000
ORDER BY UA.Reputation DESC;
