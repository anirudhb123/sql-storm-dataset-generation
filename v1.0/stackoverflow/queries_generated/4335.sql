WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalPositiveScore,
        AVG(COALESCE(CAST(C.comment AS VARCHAR(600)), '')) AS AvgCommentLength
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        COALESCE(MAX(V.VoteTypeId), 0) AS MaxVoteTypeId,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedLinksCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    WHERE 
        P.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW()
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    COALESCE(PS.PostId, -1) AS RecentPostId,
    COALESCE(PS.Title, 'No Posts') AS RecentPostTitle,
    PS.CommentCount,
    PS.MaxVoteTypeId,
    PS.RelatedLinksCount,
    UR.TotalPositiveScore,
    UR.AvgCommentLength
FROM 
    UserReputation UR
FULL OUTER JOIN 
    PostStatistics PS ON UR.UserId = PS.PostId
ORDER BY 
    UR.Reputation DESC, 
    PS.CommentCount DESC
LIMIT 100;
