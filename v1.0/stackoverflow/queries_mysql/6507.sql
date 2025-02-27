
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR THEN 1 ELSE 0 END) AS RecentPostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT TAG.TagName) AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    JOIN (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', n.n), '<', -1)) AS TagName
          FROM Posts P
          INNER JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                        UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(P.Tags)
          -CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= n.n - 1) AS TAG ON TRUE
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
),
TopUsers AS (
    SELECT 
        Us.UserId,
        Us.Reputation,
        Us.BadgeCount,
        Us.RecentPostCount,
        Us.UpvotesReceived,
        Us.DownvotesReceived,
        @rank := @rank + 1 AS Rank
    FROM UserStats Us, (SELECT @rank := 0) r
    WHERE Us.Reputation > 0
    ORDER BY Us.Reputation DESC
),
RankedPosts AS (
    SELECT 
        Pd.PostId,
        Pd.Title,
        Pd.Score,
        Pd.ViewCount,
        Pd.CommentCount,
        Pd.Tags,
        @post_rank := @post_rank + 1 AS PostRank
    FROM PostDetails Pd, (SELECT @post_rank := 0) pr
    ORDER BY Pd.Score DESC, Pd.ViewCount DESC
)
SELECT 
    Tu.UserId,
    Tu.Reputation,
    Tu.BadgeCount,
    Tu.RecentPostCount,
    Tu.UpvotesReceived,
    Tu.DownvotesReceived,
    Rp.PostId,
    Rp.Title AS PostTitle,
    Rp.Score AS PostScore,
    Rp.ViewCount AS PostViewCount,
    Rp.CommentCount AS PostCommentCount,
    Rp.Tags AS PostTags
FROM TopUsers Tu
JOIN RankedPosts Rp ON Tu.UserId = Rp.PostId
WHERE Tu.Rank <= 10 AND Rp.PostRank <= 20
ORDER BY Tu.Reputation DESC, Rp.Score DESC;
