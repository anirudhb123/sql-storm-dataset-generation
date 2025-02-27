WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Posts
    JOIN 
        LATERAL string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '>') AS TagName ON Tags.TagName = TagName
    GROUP BY 
        Tags.TagName
),
TopUsers AS (
    SELECT 
        Users.DisplayName,
        Users.Reputation,
        COUNT(Posts.Id) AS AnswerCount,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.PostTypeId = 2 -- Answers only
    GROUP BY 
        Users.DisplayName, Users.Reputation
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        Posts.Title,
        Posts.CreationDate,
        Users.DisplayName AS Author,
        COUNT(Comments.Id) AS CommentCount,
        COALESCE(MAX(Votes.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(MAX(Votes.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1 -- Questions only
    GROUP BY 
        Posts.Title, Posts.CreationDate, Users.DisplayName
),
Benchmark AS (
    SELECT 
        TagStats.TagName,
        TagStats.PostCount,
        TagStats.TotalViews,
        TagStats.TotalAnswers,
        TagStats.TotalScore,
        TopUsers.DisplayName AS TopUser,
        TopUsers.Reputation,
        PostDetails.Title,
        PostDetails.CreationDate,
        PostDetails.Author,
        PostDetails.CommentCount,
        PostDetails.UpVotes,
        PostDetails.DownVotes
    FROM 
        TagStats
    JOIN 
        TopUsers ON TagStats.PostCount > 5 -- Only include Tags with more than 5 posts
    JOIN 
        PostDetails ON TagStats.TagName = ANY(string_to_array(substring(PostDetails.Tags, 2, length(PostDetails.Tags)-2), '>')) 
    ORDER BY 
        TagStats.TotalScore DESC
)
SELECT 
    *
FROM 
    Benchmark
LIMIT 100;
