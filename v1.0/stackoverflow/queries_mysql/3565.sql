
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostAggregate AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(B.GoldCount, 0) AS GoldCount,
        COALESCE(B.SilverCount, 0) AS SilverCount,
        COALESCE(B.BronzeCount, 0) AS BronzeCount,
        P.CommentCount,
        P.TotalScore,
        P.AvgViewCount,
        P.LastPostDate,
        @row_num := @row_num + 1 AS Rank
    FROM Users U
    LEFT JOIN UserBadgeCounts B ON U.Id = B.UserId
    LEFT JOIN PostAggregate P ON U.Id = P.OwnerUserId
    CROSS JOIN (SELECT @row_num := 0) AS r
    WHERE U.Reputation > 0
)
SELECT 
    A.DisplayName,
    A.Reputation,
    A.GoldCount,
    A.SilverCount,
    A.BronzeCount,
    A.CommentCount,
    A.TotalScore,
    A.AvgViewCount,
    A.LastPostDate
FROM ActiveUsers A
WHERE A.Rank <= 10
ORDER BY A.TotalScore DESC, A.LastPostDate DESC;
