WITH TagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM
        Tags
    INNER JOIN
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY
        Tags.TagName
),
TopActiveUsers AS (
    SELECT
        Users.Id,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(CASE 
                WHEN PostTypes.Name = 'Answer' THEN 1 
                ELSE 0 
            END) AS AnswersGiven
    FROM
        Users
    INNER JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    INNER JOIN
        PostTypes ON Posts.PostTypeId = PostTypes.Id
    WHERE
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        Users.Id
    ORDER BY
        PostsCreated DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT
        PostHistory.PostId,
        PostHistory.UserDisplayName,
        PostHistory.CreationDate,
        PostHistory.Comment,
        PostHistoryType.Name AS ActionType
    FROM
        PostHistory
    INNER JOIN
        PostHistoryTypes AS PostHistoryType ON PostHistory.PostHistoryTypeId = PostHistoryType.Id
    WHERE
        PostHistory.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    T.TagName,
    T.PostCount,
    U.DisplayName AS TopUserDisplayName,
    U.PostsCreated,
    U.AnswersGiven,
    P.PostId,
    P.UserDisplayName AS EditorDisplayName,
    P.CreationDate AS EditDate,
    P.ActionType,
    P.Comment
FROM
    TagCounts T
LEFT JOIN
    TopActiveUsers U ON U.PostsCreated > 0
LEFT JOIN
    RecentPostHistory P ON P.PostId IN (SELECT PostId FROM Posts WHERE ViewCount > 100)
ORDER BY
    T.PostCount DESC, U.PostsCreated DESC, P.EditDate DESC;
