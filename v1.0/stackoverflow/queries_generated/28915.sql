WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS CountRank
    FROM 
        TagCounts
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Votes.VoteTypeId = 2, 1, 0)) AS UpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 1, 0)) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Users.CreationDate <= NOW() - INTERVAL '1 year'
    GROUP BY 
        Users.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        TotalViews,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVoteRank
    FROM 
        UserActivity
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalScore,
    U.DisplayName AS TopUser,
    U.PostsCreated,
    U.TotalViews AS UserTotalViews,
    U.UpVotes AS UserUpVotes,
    U.DownVotes AS UserDownVotes,
    T.ScoreRank,
    T.CountRank,
    U.ViewRank,
    U.UpVoteRank
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.PostsCreated > 0
WHERE 
    T.ScoreRank <= 10 AND U.ViewRank <= 10
ORDER BY 
    T.TotalScore DESC, U.TotalViews DESC;
