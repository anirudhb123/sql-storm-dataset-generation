WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    GROUP BY 
        Users.Id, Users.DisplayName, Users.Reputation
),
TopUsers AS (
    SELECT 
        UserReputation.UserId, 
        UserReputation.DisplayName, 
        UserReputation.Reputation, 
        UserReputation.PostCount, 
        UserReputation.CommentCount,
        ROW_NUMBER() OVER (ORDER BY UserReputation.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        COUNT(Comments.Id) AS TotalComments,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score
)
SELECT 
    TopUsers.DisplayName AS TopUser,
    TopUsers.Reputation AS UserReputation,
    TopUsers.PostCount AS NumberOfPosts,
    TopUsers.CommentCount AS NumberOfComments,
    PostStatistics.Title AS PostTitle,
    PostStatistics.CreationDate AS PostDate,
    PostStatistics.Score AS PostScore,
    PostStatistics.TotalComments AS PostTotalComments,
    PostStatistics.TotalUpvotes AS PostTotalUpvotes,
    PostStatistics.TotalDownvotes AS PostTotalDownvotes
FROM 
    TopUsers
JOIN 
    PostStatistics ON TopUsers.PostCount > 0
WHERE 
    TopUsers.ReputationRank <= 10
ORDER BY 
    TopUsers.Reputation DESC, PostStatistics.Score DESC;
