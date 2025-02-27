
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(CASE WHEN p.PostTypeId = 1 THEN ISNULL(p.AnswerCount, 0) ELSE NULL END) AS AvgAnswersPerQuestion
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(p.Id) AS TagCount
    FROM Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><')
    WHERE p.Tags IS NOT NULL
    GROUP BY value
    ORDER BY TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalViews,
        ua.TotalScore,
        ua.TotalPosts,
        ua.TotalComments,
        ua.AvgAnswersPerQuestion,
        ROW_NUMBER() OVER (ORDER BY ua.TotalScore DESC) AS UserRank
    FROM UserActivity ua
)

SELECT 
    ru.DisplayName, 
    ru.TotalPosts, 
    ru.TotalViews, 
    ru.TotalComments, 
    COALESCE(pt.TagName, 'No Tags') AS TopTag, 
    ru.UserRank,
    CASE 
        WHEN ru.TotalScore IS NULL THEN 'No Score'
        ELSE CASE 
            WHEN ru.TotalScore > 100 THEN 'High Performer'
            WHEN ru.TotalScore BETWEEN 50 AND 100 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END 
    END AS PerformanceCategory
FROM RankedUsers ru
LEFT JOIN (
    SELECT TagCount, TagName
    FROM PopularTags
    WHERE TagCount = (SELECT MAX(TagCount) FROM PopularTags)
) pt ON 1 = 1
WHERE ru.UserRank <= 15
ORDER BY ru.UserRank;
