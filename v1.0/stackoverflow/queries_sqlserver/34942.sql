
WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
),
TopTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            STRING_SPLIT(P.Tags, '><') AS value
        FROM Posts P
        WHERE P.PostTypeId = 1
    ) AS Tags
    GROUP BY value
    ORDER BY TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
LEFT JOIN TopTags TT ON TT.Tag IN (SELECT value FROM STRING_SPLIT(COALESCE(RP.Tags, ''), '><'))
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, TT.TagCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
