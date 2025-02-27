WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(Posts.Score) AS AverageScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ContributingUsers
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),

TagWithBadges AS (
    SELECT 
        t.TagName,
        ts.PostCount,
        ts.QuestionsCount,
        ts.AnswersCount,
        ts.AverageScore,
        ts.ContributingUsers,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        TagStatistics ts
    JOIN 
        Tags t ON t.TagName = ts.TagName
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT UNNEST(STRING_TO_ARRAY(ts.ContributingUsers, ', ')))
    GROUP BY 
        t.TagName, ts.PostCount, ts.QuestionsCount, ts.AnswersCount, ts.AverageScore, ts.ContributingUsers
),

FinalStatistics AS (
    SELECT 
        *,
        CASE 
            WHEN BadgeCount > 0 THEN 'Yes'
            ELSE 'No'
        END AS HasBadges
    FROM 
        TagWithBadges
)

SELECT 
    TagName,
    PostCount,
    QuestionsCount,
    AnswersCount,
    AverageScore,
    ContributingUsers,
    HasBadges
FROM 
    FinalStatistics
ORDER BY 
    PostCount DESC, 
    AverageScore DESC
LIMIT 10;
