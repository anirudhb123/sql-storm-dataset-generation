WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews
    FROM
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(COALESCE(Votes.UserId = Users.Id, 0)) AS TotalVotes,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY PostsCreated DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    u.DisplayName AS TopUser,
    u.PostsCreated,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.Rank = 1
ORDER BY 
    t.Rank, u.PostsCreated DESC;
