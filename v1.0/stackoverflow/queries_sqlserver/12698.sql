
WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts, 
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners 
    FROM 
        Posts
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers, 
        AVG(Reputation) AS AverageReputation 
    FROM 
        Users
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments 
    FROM 
        Comments
),
VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes 
    FROM 
        Votes
),
BadgeCounts AS (
    SELECT 
        COUNT(*) AS TotalBadges 
    FROM 
        Badges
)
SELECT 
    p.TotalPosts, 
    p.UniquePostOwners, 
    u.TotalUsers, 
    u.AverageReputation, 
    c.TotalComments, 
    v.TotalVotes, 
    b.TotalBadges 
FROM 
    PostCounts p CROSS JOIN
    UserCounts u CROSS JOIN
    CommentCounts c CROSS JOIN
    VoteCounts v CROSS JOIN
    BadgeCounts b;
