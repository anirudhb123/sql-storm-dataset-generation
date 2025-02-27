WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(B.Class) AS BadgeScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS EngagementRank,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
)
SELECT 
    US.DisplayName,
    US.PostCount,
    US.CommentCount,
    US.UpVotes,
    US.DownVotes,
    US.BadgeScore,
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.EngagementRank,
    PE.TotalComments
FROM 
    UserStats US
JOIN 
    PostEngagement PE ON US.UserId = P.OwnerUserId
ORDER BY 
    US.BadgeScore DESC, 
    PE.EngagementRank;
