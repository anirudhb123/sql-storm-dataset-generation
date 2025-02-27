
WITH RecursiveUserScores AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, U.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RowNum
    FROM Users U
), 
UserBadges AS (
    SELECT B.UserId, COUNT(*) AS BadgeCount, 
           STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId, 
           P.ViewCount, P.Tags,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= CAST('2024-10-01' AS DATE) - 30
),
PopularTags AS (
    SELECT TRIM(value) AS TagName,
           COUNT(*) AS TagCount
    FROM Posts P
    CROSS APPLY STRING_SPLIT(P.Tags, ' ') AS value
    WHERE P.Tags IS NOT NULL
    GROUP BY TRIM(value)
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
LEFT JOIN PopularTags PT ON PT.TagName = TRIM(value)
WHERE U.Reputation > 1000
  AND U.CreationDate <= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
ORDER BY U.Reputation DESC, LastPostScore DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
