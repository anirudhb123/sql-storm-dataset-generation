
WITH TagCounts AS (
    SELECT Tags, COUNT(*) AS PostCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY Tags
),
TopTags AS (
    SELECT 
        TagName,
        SUM(PostCount) AS TotalPosts
    FROM TagCounts
    JOIN (
        SELECT 
            TRIM(value) AS TagName
        FROM TagCounts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) 
        ) AS Tag
        WHERE Tags LIKE '%' || Tag.value || '%'
    ) AS Tag ON Tags LIKE '%' || Tag.TagName || '%'
    GROUP BY TagName
    ORDER BY TotalPosts DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
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
        COUNT(*) AS ActivityCount,
        LISTAGG(DISTINCT U.DisplayName, ', ') WITHIN GROUP (ORDER BY U.DisplayName) AS UsersInvolved
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
