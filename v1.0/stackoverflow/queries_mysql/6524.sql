
WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           BadgeCount, 
           GoldBadges, 
           SilverBadges, 
           BronzeBadges,
           @rownum := @rownum + 1 AS BadgeRank
    FROM UserBadges, (SELECT @rownum := 0) r
    ORDER BY BadgeCount DESC
),
PostDetails AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.CreationDate, 
           P.ViewCount, 
           P.Score, 
           U.DisplayName AS OwnerDisplayName,
           U.Reputation AS OwnerReputation,
           @postRank := @postRank + 1 AS PostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id, (SELECT @postRank := 0) r
),
TopPosts AS (
    SELECT PostId, 
           Title, 
           CreationDate, 
           ViewCount, 
           Score, 
           OwnerDisplayName, 
           OwnerReputation,
           PostRank
    FROM PostDetails
    WHERE PostRank <= 10
)
SELECT T.DisplayName AS TopUser, 
       T.BadgeCount AS UserBadgeCount, 
       T.GoldBadges, 
       T.SilverBadges, 
       T.BronzeBadges, 
       P.Title AS TopPostTitle, 
       P.ViewCount AS TopPostViews, 
       P.Score AS TopPostScore, 
       P.CreationDate AS TopPostCreationDate
FROM TopUsers T
JOIN TopPosts P ON T.DisplayName = P.OwnerDisplayName
ORDER BY T.BadgeRank, P.Score DESC;
