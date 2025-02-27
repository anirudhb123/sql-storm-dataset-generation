-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Comments.Id IS NOT NULL) AS CommentCount,
        SUM(Votes.Id IS NOT NULL) AS VoteCount,
        SUM(Badges.Id IS NOT NULL) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),
PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        Posts.Score,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Votes.Id) AS VoteCount
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.CommentCount AS UserCommentCount,
    u.VoteCount AS UserVoteCount,
    u.BadgeCount,
    p.PostId,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score AS PostScore,
    p.CommentCount AS PostCommentCount,
    p.VoteCount AS PostVoteCount
FROM 
    UserStats u
JOIN 
    PostStats p ON p.PostId IN (
        SELECT Id 
        FROM Posts 
        WHERE OwnerUserId = u.UserId
    )
ORDER BY 
    u.Reputation DESC, p.ViewCount DESC
LIMIT 50; -- Limiting the output to the top 50 users and their posts
