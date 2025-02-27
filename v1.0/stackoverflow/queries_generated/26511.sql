WITH TagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tags.TagName
),
ActiveUsers AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        COUNT(DISTINCT Comments.Id) AS CommentsMade,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Votes.UserId = Users.Id
    WHERE 
        Users.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Users.Id, Users.Reputation
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagUsage
)
SELECT 
    a.UserId,
    a.Reputation,
    a.PostsCreated,
    a.CommentsMade,
    a.UpVotesReceived,
    a.DownVotesReceived,
    t.TagName,
    t.TotalViews,
    t.TotalAnswers
FROM 
    ActiveUsers a
JOIN 
    TopTags t ON a.PostsCreated > 5
WHERE 
    t.Rank <= 10
ORDER BY 
    a.Reputation DESC, t.TotalViews DESC;
