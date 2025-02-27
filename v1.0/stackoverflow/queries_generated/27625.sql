WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
), 
UserEngagement AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(Votes.VoteTypeId = 2) AS UpVotesReceived,
        SUM(Votes.VoteTypeId = 3) AS DownVotesReceived
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
TopUsers AS (
    SELECT 
        UserEngagement.UserId,
        UserEngagement.DisplayName,
        UserEngagement.PostsCreated,
        UserEngagement.UpVotesReceived - UserEngagement.DownVotesReceived AS NetVotes
    FROM 
        UserEngagement
    WHERE 
        UserEngagement.PostsCreated > 0
    ORDER BY 
        NetVotes DESC
    LIMIT 10
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    U.DisplayName AS TopUser,
    U.NetVotes
FROM 
    TagStats T
LEFT JOIN 
    TopUsers U ON T.PostCount = (
        SELECT 
            MAX(PostCount) 
        FROM 
            TagStats
    )
ORDER BY 
    T.TotalScore DESC;
