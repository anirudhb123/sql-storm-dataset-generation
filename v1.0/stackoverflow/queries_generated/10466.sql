-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        post.Id AS PostId,
        post.Title,
        post.CreationDate,
        COUNT(DISTINCT comment.Id) AS CommentCount,
        COUNT(DISTINCT vote.Id) AS VoteCount,
        SUM(CASE WHEN post.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN post.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts post
    LEFT JOIN 
        Comments comment ON post.Id = comment.PostId
    LEFT JOIN 
        Votes vote ON post.Id = vote.PostId
    GROUP BY 
        post.Id, post.Title, post.CreationDate
),
UserStats AS (
    SELECT 
        user.Id AS UserId,
        user.DisplayName,
        SUM(CASE WHEN badge.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN badge.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN badge.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(user.Reputation) AS AverageReputation
    FROM 
        Users user
    LEFT JOIN 
        Badges badge ON user.Id = badge.UserId
    GROUP BY 
        user.Id, user.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    us.DisplayName AS UserDisplayName,
    us.AverageReputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC;
