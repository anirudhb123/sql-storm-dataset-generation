WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.Score) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalScore,
        Rank
    FROM UserActivity
    WHERE Rank <= 10
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN UNNEST(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE
    GROUP BY P.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    PT.Tags,
    COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN U.TotalScore > 1000 THEN 'Expert'
        WHEN U.TotalScore > 500 THEN 'Pro'
        ELSE 'Novice'
    END AS UserLevel
FROM TopUsers U
LEFT JOIN (
    SELECT UserId, COUNT(Id) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
) BadgeCount ON U.UserId = BadgeCount.UserId
LEFT JOIN PostTags PT ON PT.PostId IN (
    SELECT P.Id 
    FROM Posts P 
    WHERE P.OwnerUserId = U.UserId
)
ORDER BY U.TotalScore DESC, U.DisplayName;
