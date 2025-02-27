
WITH RecursiveUserScores AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, U.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RowNum
    FROM Users U
), 
UserBadges AS (
    SELECT B.UserId, COUNT(*) AS BadgeCount, 
           GROUP_CONCAT(B.Name ORDER BY B.Name SEPARATOR ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId, 
           P.ViewCount, P.Tags,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
PopularTags AS (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ' ', numbers.n), ' ', -1)) AS TagName,
           COUNT(*) AS TagCount
    FROM Posts P
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ' ', '')) >= numbers.n - 1
    WHERE P.Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
)
SELECT U.DisplayName, U.Reputation, 
       COALESCE(UB.BadgeCount, 0) AS TotalBadges, 
       COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
       RP.Title AS LastPostTitle, RP.Score AS LastPostScore, 
       RP.ViewCount AS LastPostViews,
       PT.TagName AS PopularTag, PT.TagCount
FROM RecursiveUserScores U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.PostRank = 1
LEFT JOIN PopularTags PT ON FIND_IN_SET(PT.TagName, RP.Tags) > 0
WHERE U.Reputation > 1000
  AND U.CreationDate <= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
ORDER BY U.Reputation DESC, LastPostScore DESC
LIMIT 50;
