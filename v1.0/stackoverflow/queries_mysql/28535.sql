
WITH TagCounts AS (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
           COUNT(*) AS PostCount
    FROM Posts
    JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
          SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
    GROUP BY SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)
),
TopTags AS (
    SELECT TagName,
           PostCount,
           @rank := @rank + 1 AS Rank
    FROM TagCounts, (SELECT @rank := 0) r
    WHERE PostCount > 1
    ORDER BY PostCount DESC
),
TopUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(U.UpVotes) AS TotalUpVotes,
           SUM(U.DownVotes) AS TotalDownVotes,
           COUNT(B.Id) AS BadgeCount,
           @userRank := @userRank + 1 AS UserRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    JOIN (SELECT @userRank := 0) ur
    GROUP BY U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT P.Id,
           P.Title,
           P.Score,
           P.ViewCount,
           P.CreationDate,
           U.DisplayName AS OwnerDisplayName,
           GROUP_CONCAT(DISTINCT T.TagName) AS Tags
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN TagCounts T ON FIND_IN_SET(T.TagName, REPLACE(REPLACE(P.Tags, '<', ''), '>', ''))
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, U.DisplayName
    HAVING COUNT(DISTINCT T.TagName) > 1
    ORDER BY P.Score DESC, P.ViewCount DESC
    LIMIT 5
)
SELECT T.TagName,
       T.PostCount,
       U.DisplayName AS TopUser,
       U.TotalUpVotes,
       U.TotalDownVotes,
       U.BadgeCount,
       P.Title AS PopularPostTitle,
       P.Score AS PopularPostScore,
       P.ViewCount AS PopularPostViewCount
FROM TopTags T
JOIN TopUsers U ON U.UserRank <= 10
JOIN PopularPosts P ON FIND_IN_SET(T.TagName, P.Tags)
ORDER BY T.PostCount DESC, U.TotalUpVotes DESC;
