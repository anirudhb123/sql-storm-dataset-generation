WITH TagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN Posts.AnswerCount ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags
    LEFT JOIN
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, ',')::int[])
    GROUP BY
        Tags.TagName
),
UserReputations AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(CASE WHEN Badges.Class = 1 THEN 3 WHEN Badges.Class = 2 THEN 2 WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BadgeScore,
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM
        Users
    LEFT JOIN
        Badges ON Users.Id = Badges.UserId
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY
        Users.Id, Users.DisplayName
),
PopularTags AS (
    SELECT
        TagCounts.TagName,
        TagCounts.PostCount,
        (TagCounts.QuestionCount + TagCounts.AnswerCount) AS TotalActivities
    FROM
        TagCounts
    WHERE
        TagCounts.PostCount > 0
    ORDER BY
        TotalActivities DESC
    LIMIT 10
),
UserContributions AS (
    SELECT
        UserReputations.DisplayName,
        UserReputations.BadgeScore,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(Comments.Score) AS TotalCommentScore
    FROM
        UserReputations
    LEFT JOIN
        Comments ON UserReputations.UserId = Comments.UserId
    GROUP BY
        UserReputations.DisplayName, UserReputations.BadgeScore
)

SELECT
    PT.TagName,
    UC.DisplayName,
    UC.BadgeScore,
    UC.CommentCount,
    UC.TotalCommentScore
FROM
    PopularTags PT
JOIN
    UserContributions UC ON UC.BadgeScore > 0
WHERE
    PT.TagName LIKE '%SQL%'
ORDER BY
    UC.TotalCommentScore DESC;
