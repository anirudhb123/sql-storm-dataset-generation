-- Performance Benchmarking Query

-- This query calculates the average number of comments per post, 
-- total votes per user, and total badges awarded, 
-- to assess the performance and efficiency of the database schema.

WITH CommentsPerPost AS (
    SELECT 
        PostId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
VotesPerUser AS (
    SELECT 
        UserId,
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
BadgesPerUser AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    (SELECT AVG(CommentCount) FROM CommentsPerPost) AS AvgCommentsPerPost,
    (SELECT SUM(VoteCount) FROM VotesPerUser) AS TotalVotes,
    (SELECT SUM(BadgeCount) FROM BadgesPerUser) AS TotalBadges

