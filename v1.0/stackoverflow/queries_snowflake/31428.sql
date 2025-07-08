
WITH RecursiveUserScores AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, U.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RowNum
    FROM Users U
), 
UserBadges AS (
    SELECT B.UserId, COUNT(*) AS BadgeCount, 
           LISTAGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId, 
           P.ViewCount, P.Tags,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(DAY, -30, '2024-10-01'::DATE)
),
PopularTags AS (
    SELECT TRIM(value) AS TagName,
           COUNT(*) AS TagCount
    FROM (
        SELECT TRIM(unnest(split_to_array(P.Tags, ' '))) AS value
        FROM Posts P
        WHERE P.Tags IS NOT NULL
    )
    GROUP BY TRIM(value)
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
LEFT JOIN PopularTags PT ON PT.TagName = ANY(split_to_array(RP.Tags, ' '))
WHERE U.Reputation > 1000
  AND U.CreationDate <= DATEADD(YEAR, -1, '2024-10-01 12:34:56'::TIMESTAMP)
ORDER BY U.Reputation DESC, LastPostScore DESC
LIMIT 50;
