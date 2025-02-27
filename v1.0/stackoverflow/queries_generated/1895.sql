WITH UserReputation AS (
    SELECT 
        Id AS UserID,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
), PostStats AS (
    SELECT 
        Posts.Id AS PostID,
        Posts.OwnerUserId,
        Posts.ViewCount,
        COALESCE(SUM(Votes.VoteTypeId = 2) - SUM(Votes.VoteTypeId = 3), 0) AS Score,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT PostLinks.Id) AS LinkedPostCount
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        PostLinks ON Posts.Id = PostLinks.PostId
    WHERE 
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.OwnerUserId, Posts.ViewCount
), UserActivity AS (
    SELECT 
        UserID,
        COUNT(PostID) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        MAX(Score) AS MaxScore
    FROM 
        PostStats
    JOIN 
        UserReputation ON UserReputation.UserID = PostStats.OwnerUserId
    GROUP BY 
        UserID
), HighPerformingUsers AS (
    SELECT 
        U.UserID, 
        U.DisplayName, 
        UA.PostCount, 
        UA.AvgViewCount, 
        UA.MaxScore,
        CASE 
            WHEN UA.PostCount > 10 THEN 'Active'
            WHEN UA.AvgViewCount > 100 THEN 'Influential'
            ELSE 'Moderate'
        END AS UserCategory
    FROM 
        UserReputation U
    JOIN 
        UserActivity UA ON U.UserID = UA.UserID
    WHERE 
        U.Reputation > 1000
)
SELECT 
    H.UserID,
    H.DisplayName,
    H.PostCount,
    H.AvgViewCount,
    H.MaxScore,
    H.UserCategory,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score
FROM 
    HighPerformingUsers H
LEFT JOIN 
    PostStats P ON H.UserID = P.OwnerUserId
WHERE 
    H.MaxScore > 0 OR H.PostCount > 5
ORDER BY 
    H.MaxScore DESC, H.PostCount DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
