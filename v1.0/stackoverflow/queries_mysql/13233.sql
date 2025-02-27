
WITH PostActivity AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.CreationDate AS PostCreationDate,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = Posts.Id) AS EditCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Badges ON Posts.OwnerUserId = Badges.UserId
    GROUP BY 
        Posts.Id, Posts.CreationDate
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation AS Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(PostActivity.CommentCount) AS TotalComments,
        SUM(PostActivity.VoteCount) AS TotalVotes,
        SUM(PostActivity.EditCount) AS TotalEdits,
        SUM(PostActivity.BadgeCount) AS TotalBadges
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        PostActivity ON Posts.Id = PostActivity.PostId
    GROUP BY 
        Users.Id, Users.Reputation
)
SELECT 
    UserActivity.UserId,
    UserActivity.Reputation,
    UserActivity.PostCount,
    UserActivity.TotalComments,
    UserActivity.TotalVotes,
    UserActivity.TotalEdits,
    UserActivity.TotalBadges,
    (SELECT AVG(Reputation) FROM UserActivity) AS AvgReputation,
    (SELECT AVG(PostCount) FROM UserActivity) AS AvgPosts,
    (SELECT AVG(TotalComments) FROM UserActivity) AS AvgComments,
    (SELECT AVG(TotalVotes) FROM UserActivity) AS AvgVotes,
    (SELECT AVG(TotalEdits) FROM UserActivity) AS AvgEdits,
    (SELECT AVG(TotalBadges) FROM UserActivity) AS AvgBadges
FROM 
    UserActivity
ORDER BY 
    UserActivity.Reputation DESC;
