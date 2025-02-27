WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),

HighScoreTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore
    FROM 
        HighScoreTags
    WHERE 
        Rank <= 10
),

UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Votes.VoteTypeId IN (2)) AS UpVotes,
        SUM(Votes.VoteTypeId IN (3)) AS DownVotes,
        SUM(Comments.Id IS NOT NULL) AS CommentCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
    HAVING 
        COUNT(DISTINCT Posts.Id) >= 5
)

SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    u.UserId,
    u.DisplayName,
    u.PostCount AS UserPostCount,
    u.UpVotes,
    u.DownVotes,
    u.CommentCount
FROM 
    TopTags t
JOIN 
    UserActivity u ON u.PostCount > 0
ORDER BY 
    t.TotalScore DESC, u.UpVotes DESC;
