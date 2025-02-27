
WITH TagCounts AS (
    SELECT Tags, COUNT(*) as PostCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY Tags
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) as TotalPosts
    FROM TagCounts
    JOIN (
        SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
        FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
        WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    ) AS Tag ON Tags LIKE CONCAT('%', Tag.TagName, '%')
    GROUP BY TagName
    ORDER BY TotalPosts DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.DisplayName,
        SUM(P.ViewCount) as TotalViews,
        SUM(P.Score) as TotalScore,
        COUNT(C.Id) as TotalComments,
        COUNT(DISTINCT B.Id) as TotalBadges
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.DisplayName
    ORDER BY TotalViews DESC
    LIMIT 5
),
PostHistoryActivity AS (
    SELECT 
        PH.PostHistoryTypeId,
        COUNT(*) as ActivityCount,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName ASC SEPARATOR ', ') as UsersInvolved
    FROM PostHistory PH
    JOIN Users U ON PH.UserId = U.Id
    GROUP BY PH.PostHistoryTypeId
    ORDER BY ActivityCount DESC
)

SELECT 
    T.TagName,
    T.TotalPosts,
    U.DisplayName,
    U.TotalViews,
    U.TotalScore,
    U.TotalComments,
    U.TotalBadges,
    PHA.PostHistoryTypeId,
    PHA.ActivityCount,
    PHA.UsersInvolved
FROM TopTags T
JOIN UserActivity U ON TRUE
JOIN PostHistoryActivity PHA ON TRUE
ORDER BY T.TotalPosts DESC, U.TotalViews DESC, PHA.ActivityCount DESC;
