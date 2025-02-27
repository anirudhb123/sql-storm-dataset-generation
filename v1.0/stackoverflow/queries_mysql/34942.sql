
WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        @row_number := @row_number + 1 AS Rank
    FROM Users U, (SELECT @row_number := 0) AS r
    ORDER BY U.Reputation DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        P.Tags,
        @recent_post_row_number := IF(@current_owner = P.OwnerUserId, @recent_post_row_number + 1, 1) AS RecentPostRank,
        @current_owner := P.OwnerUserId
    FROM Posts P, (SELECT @recent_post_row_number := 0, @current_owner := NULL) AS rp
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY P.OwnerUserId, P.CreationDate DESC
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM Posts P
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 n
        FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n
    WHERE n.n <= 1 + LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '><', ''))
    AND P.PostTypeId = 1
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
PostCommentsCount AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    TT.Tag,
    TT.TagCount
FROM RecursiveUserStats U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN PostCommentsCount PC ON RP.PostId = PC.PostId
LEFT JOIN TopTags TT ON FIND_IN_SET(TT.Tag, COALESCE(RP.Tags, '')) > 0
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, TT.TagCount DESC
LIMIT 100;
