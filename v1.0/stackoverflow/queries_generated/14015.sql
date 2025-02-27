-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.CreationDate, 
        Posts.ViewCount, 
        Posts.Score,
        Users.Reputation AS OwnerReputation,
        COUNT(COMMENTS.Id) AS CommentCount,
        COUNT(VOTES.Id) AS VoteCount
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Users.Reputation
),
BadgeStatistics AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.OwnerReputation,
    PS.CommentCount,
    PS.VoteCount,
    COALESCE(BS.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    PostStatistics PS
LEFT JOIN 
    BadgeStatistics BS ON PS.OwnerUserId = BS.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100; -- Adjust limit as needed for benchmarking
