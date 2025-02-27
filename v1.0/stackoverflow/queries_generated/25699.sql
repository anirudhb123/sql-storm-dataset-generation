WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(COALESCE(Posts.AnswerCount, 0)) AS AvgAnswers,
        AVG(COALESCE(Posts.CommentCount, 0)) AS AvgComments
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserStats AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.DisplayName
),
PopularPosts AS (
    SELECT 
        Posts.Id,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Users.DisplayName AS Author
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.Score > (SELECT AVG(Score) FROM Posts)
    ORDER BY 
        Posts.Score DESC
    LIMIT 10
)

SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    T.AvgAnswers,
    T.AvgComments,
    U.DisplayName AS TopAuthor,
    U.PostsCount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.AvgReputation,
    PP.Title AS PopularPostTitle,
    PP.CreationDate AS PopularPostDate,
    PP.Score AS PopularPostScore
FROM 
    TagStats T
JOIN 
    UserStats U ON T.PostCount = U.PostsCount -- join condition to correlate tags with user stats
LEFT JOIN 
    PopularPosts PP ON PP.Author = U.DisplayName
ORDER BY 
    T.TotalViews DESC, U.TotalUpVotes DESC;
