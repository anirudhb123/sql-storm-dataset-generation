WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        SUM(CASE WHEN Posts.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredPosts,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substr(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserStats AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(Votes.VoteTypeId = 2) AS TotalUpVotes,
        SUM(Votes.VoteTypeId = 3) AS TotalDownVotes,
        AVG(DATEDIFF('minute', Posts.CreationDate, NOW())) AS AveragePostAge
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        HighViewCountPosts,
        AnsweredPosts,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
TopUsers AS (
    SELECT 
        DisplayName,
        PostsCreated,
        QuestionsAsked,
        AnswersGiven,
        TotalUpVotes,
        TotalDownVotes,
        AveragePostAge,
        ROW_NUMBER() OVER (ORDER BY TotalUpVotes DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    t.TagName,
    t.PostCount,
    t.HighViewCountPosts,
    t.AnsweredPosts,
    t.AverageScore,
    u.DisplayName,
    u.PostsCreated,
    u.QuestionsAsked,
    u.AnswersGiven,
    u.TotalUpVotes,
    u.TotalDownVotes
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.Rank = 1
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC, u.TotalUpVotes DESC;
