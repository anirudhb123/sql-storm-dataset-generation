WITH FrequentTags AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount
    FROM 
        Posts
    JOIN 
        Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(Posts.Id) > 50
), 
QualityPosts AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.CreationDate, 
        Posts.ViewCount, 
        Users.DisplayName AS Owner, 
        COALESCE(Posts.AcceptedAnswerId IS NOT NULL, FALSE) AS HasAcceptedAnswer, 
        COUNT(Comments.Id) AS CommentCount
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    WHERE 
        Posts.PostTypeId = 1 AND 
        Posts.ViewCount > 1000
    GROUP BY 
        Posts.Id, Users.DisplayName
), 
ActiveUsers AS (
    SELECT 
        Users.Id, 
        Users.DisplayName, 
        COUNT(Posts.Id) AS PostsCreated,
        SUM(CASE WHEN Posts.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostsCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
    HAVING 
        COUNT(Posts.Id) > 10
)
SELECT 
    ft.TagName,
    qp.Title AS QualityPostTitle,
    qp.Owner,
    qp.CreationDate,
    qp.ViewCount,
    au.DisplayName AS ActiveUserName,
    au.PostsCreated,
    au.PopularPostsCount
FROM 
    FrequentTags ft
JOIN 
    PostLinks pl ON ft.TagName = ANY(string_to_array(substring(pl.Posts.Tags, 2, length(pl.Posts.Tags) - 2), '><'))
JOIN 
    QualityPosts qp ON pl.RelatedPostId = qp.PostId
JOIN 
    ActiveUsers au ON qp.Owner = au.DisplayName
ORDER BY 
    ft.TagName, qp.ViewCount DESC
LIMIT 100;
