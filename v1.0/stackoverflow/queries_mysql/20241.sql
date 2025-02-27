
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.UpModCount, 0)) AS TotalUpvotes,
        SUM(COALESCE(V.DownModCount, 0)) AS TotalDownvotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpModCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownModCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostsWithTags AS (
    SELECT 
        P.*, 
        GROUP_CONCAT(T.TagName SEPARATOR ', ') AS TagsAggregated
    FROM Posts P
    LEFT JOIN (
        SELECT 
            DISTINCT P.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) AS TagName
        FROM Posts P
        INNER JOIN (
            SELECT 
                1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= n.n - 1
    ) T ON P.Id = T.PostId
    GROUP BY P.Id
),
TopPosts AS (
    SELECT 
        PW.*, 
        @row_number := IF(@prev_user = PW.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_user := PW.OwnerUserId
    FROM PostsWithTags PW, (SELECT @row_number := 0, @prev_user := NULL) r
    WHERE PW.ViewCount IS NOT NULL
    ORDER BY PW.OwnerUserId, PW.ViewCount DESC
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    TP.Title,
    TP.ViewCount,
    TP.CreationDate,
    TP.TagsAggregated
FROM UserActivity UA
JOIN TopPosts TP ON UA.UserId = TP.OwnerUserId
WHERE UA.Reputation > 1000 
    AND TP.Rank <= 3
    AND (TP.ClosedDate IS NULL OR 
    (TP.ClosedDate IS NOT NULL AND TP.CreationDate < '2024-10-01 12:34:56' - INTERVAL 1 YEAR))
ORDER BY UA.Reputation DESC, TP.ViewCount DESC
LIMIT 10 OFFSET 5;
