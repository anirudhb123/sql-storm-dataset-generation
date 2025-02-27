WITH RankedTags AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(Posts.Id) DESC) AS Rank
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Votes.VoteTypeId IN (2), 0)) AS UpVotes,
        SUM(COALESCE(Votes.VoteTypeId IN (3), 0)) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    GROUP BY 
        Users.Id, Users.Reputation
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        COALESCE(Comments.CommentCount, 0) AS TotalComments,
        COALESCE(PostLinks.LinkCount, 0) AS TotalLinks,
        (SELECT STRING_AGG(CONCAT('Tag: ', TagName), ', ') 
         FROM RankedTags 
         WHERE Rank <= 5 AND Posts.Tags LIKE '%' || TagName || '%') AS TopTags
    FROM 
        Posts
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments GROUP BY PostId) AS Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS LinkCount 
         FROM PostLinks GROUP BY PostId) AS PostLinks ON Posts.Id = PostLinks.PostId
)
SELECT 
    UserReputation.UserId,
    UserReputation.Reputation,
    UserReputation.PostCount,
    UserReputation.UpVotes,
    UserReputation.DownVotes,
    PostStatistics.PostId,
    PostStatistics.Title,
    PostStatistics.CreationDate,
    PostStatistics.Score,
    PostStatistics.TotalComments,
    PostStatistics.TotalLinks,
    PostStatistics.TopTags
FROM 
    UserReputation
JOIN 
    Posts ON UserReputation.PostCount > 0
JOIN 
    PostStatistics ON Posts.Id = PostStatistics.PostId
ORDER BY 
    UserReputation.Reputation DESC, PostStatistics.Score DESC;
