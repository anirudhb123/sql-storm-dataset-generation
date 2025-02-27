-- Performance Benchmarking SQL Query
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        COUNT(Votes.Id) AS VoteCount,
        COUNT(Comments.Id) AS CommentCount,
        MAX(Posts.CreationDate) AS LastActivityDate
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.PostTypeId
),
UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        AVG(Users.Reputation) AS AvgReputation,
        SUM(Badges.Class = 1) AS GoldBadges,
        SUM(Badges.Class = 2) AS SilverBadges,
        SUM(Badges.Class = 3) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.VoteCount,
    PS.CommentCount,
    PS.LastActivityDate,
    US.UserId,
    US.AvgReputation,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges
FROM 
    PostStatistics PS
JOIN 
    Users U ON PS.PostTypeId = U.Id  -- Assuming we want to map users by PostTypeId for demo
JOIN 
    UserStatistics US ON US.UserId = PS.PostId
ORDER BY 
    PS.LastActivityDate DESC;
