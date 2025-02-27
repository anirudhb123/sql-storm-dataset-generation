WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id IN (SELECT UNNEST(string_to_array(Tags, '><'))::int)
    GROUP BY 
        Tags.TagName
),
TopUsers AS (
    SELECT 
        Users.DisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        AVG(Posts.Score) AS AveragePostScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
),
TopTags AS (
    SELECT 
        TagStatistics.TagName,
        TagStatistics.PostCount,
        TagStatistics.QuestionCount,
        TagStatistics.AnswerCount,
        TagStatistics.TotalViews,
        TagStatistics.AverageScore,
        ROW_NUMBER() OVER (ORDER BY TagStatistics.PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    TopUsers.DisplayName AS "Top User",
    TopUsers.TotalUpVotes AS "Total Upvotes",
    TopUsers.TotalDownVotes AS "Total Downvotes",
    TopUsers.TotalPosts AS "Total Posts",
    TopUsers.AveragePostScore AS "Average Post Score",
    TopTags.TagName AS "Top Tag",
    TopTags.PostCount AS "Tag Post Count",
    TopTags.QuestionCount AS "Tag Question Count",
    TopTags.AnswerCount AS "Tag Answer Count",
    TopTags.TotalViews AS "Tag Total Views",
    TopTags.AverageScore AS "Tag Average Score"
FROM 
    TopUsers
CROSS JOIN 
    TopTags
WHERE 
    TopTags.TagRank <= 5;  -- Getting top 5 tags
