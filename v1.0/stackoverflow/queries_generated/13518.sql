-- Performance Benchmarking Query
WITH UsersStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = Users.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS BadgeCount
    FROM 
        Users
),
PostStats AS (
    SELECT 
        Id AS PostId,
        PostTypeId,
        Score,
        ViewCount,
        CreationDate,
        LastActivityDate,
        (SELECT COUNT(*) FROM Comments WHERE PostId = Posts.Id) AS CommentCount,
        (SELECT SUM(BountyAmount) FROM Votes WHERE PostId = Posts.Id AND VoteTypeId IN (8, 9)) AS TotalBounty,
        (SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id) AS VoteCount
    FROM 
        Posts
)
SELECT 
    u.UserId,
    u.Reputation,
    p.PostId,
    p.PostTypeId,
    p.Score,
    p.ViewCount,
    p.CommentCount AS PostCommentCount,
    u.PostCount AS UserPostCount,
    u.CommentCount AS UserCommentCount,
    u.BadgeCount AS UserBadgeCount,
    p.TotalBounty,
    p.VoteCount
FROM 
    UsersStats u
JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    p.Score DESC, u.Reputation DESC
LIMIT 100;
