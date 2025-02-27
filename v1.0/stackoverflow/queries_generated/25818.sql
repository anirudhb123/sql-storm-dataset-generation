WITH TagMetrics AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(COALESCE(Posts.Score, 0)) AS AvgScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ActiveUsers
    FROM
        Tags
    LEFT JOIN
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    LEFT JOIN
        Users ON Posts.OwnerUserId = Users.Id
    WHERE
        Posts.CreationDate >= NOW() - INTERVAL '1 year'  -- Analyze only recent posts
    GROUP BY
        Tags.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC, AvgScore DESC) AS Rank
    FROM
        TagMetrics
),
UserEngagement AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Votes.Id) AS VoteCount,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Badges.Id) AS BadgeCount
    FROM
        Users
    LEFT JOIN
        Votes ON Votes.UserId = Users.Id
    LEFT JOIN
        Comments ON Comments.UserId = Users.Id
    LEFT JOIN
        Badges ON Badges.UserId = Users.Id
    GROUP BY
        Users.Id
)
SELECT
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AvgScore,
    t.Rank,
    u.DisplayName AS TopUser,
    u.VoteCount,
    u.CommentCount,
    u.BadgeCount
FROM
    TopTags t
LEFT JOIN (
    SELECT DISTINCT ON (PostId)
        Posts.Id AS PostId,
        Users.DisplayName,
        UserEngagement.VoteCount,
        UserEngagement.CommentCount,
        UserEngagement.BadgeCount
    FROM
        Posts
    JOIN
        UserEngagement ON Posts.OwnerUserId = UserEngagement.UserId
    ORDER BY
        Posts.ViewCount DESC  -- Get top engaged user for each post
) AS u ON u.PostId = t.PostCount
WHERE
    t.Rank <= 10  -- Limit to top 10 tags
ORDER BY
    t.Rank;
