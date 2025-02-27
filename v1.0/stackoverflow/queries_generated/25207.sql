WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionsAsked,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId 
    GROUP BY 
        Users.Id, Users.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        TotalUpvotes, 
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS UpvoteRank
    FROM 
        UserActivity
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.TotalAnswers,
    u.DisplayName AS TopUser,
    u.QuestionsAsked,
    u.TotalUpvotes
FROM 
    TopTags t
JOIN 
    PopularUsers u ON u.QuestionsAsked > 0
WHERE 
    t.TagRank <= 5 AND u.UpvoteRank <= 10
ORDER BY 
    t.PostCount DESC, u.TotalUpvotes DESC;
