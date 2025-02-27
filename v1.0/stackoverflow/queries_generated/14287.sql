-- Performance Benchmarking Query for Stack Overflow Schema
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        MAX(P.CreationDate) AS PostCreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    GROUP BY 
        P.Id, P.PostTypeId, P.OwnerUserId, P.Title, P.Score, P.ViewCount
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(VoteCount) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) V ON V.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.TotalVotes
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.OwnerUserId = US.UserId
WHERE 
    PS.PostTypeId = 1  -- filtering for Questions only
ORDER BY 
    PS.Score DESC
LIMIT 100; -- Limit to top 100 posts by score
