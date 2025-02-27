
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
    CROSS APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    ) AS Tag
    WHERE Tags LIKE '%' + TagName + '%'
    GROUP BY TagName
    ORDER BY TotalPosts DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
PostHistoryActivity AS (
    SELECT 
        PH.PostHistoryTypeId,
        COUNT(*) AS ActivityCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS UsersInvolved
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
CROSS JOIN UserActivity U
CROSS JOIN PostHistoryActivity PHA
ORDER BY T.TotalPosts DESC, U.TotalViews DESC, PHA.ActivityCount DESC;
