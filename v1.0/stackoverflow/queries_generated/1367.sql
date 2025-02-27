WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        TotalPosts,
        TotalComments,
        Rank
    FROM 
        UserScores
    WHERE 
        Rank <= 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        P.AcceptedAnswerId,
        PA.Body AS AcceptedAnswerBody
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId, PA.Body
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalBounties,
    TU.TotalPosts,
    TU.TotalComments,
    PS.Title AS PostTitle,
    PS.Score AS PostScore,
    PS.ViewCount,
    PS.CommentCount,
    PS.AcceptedAnswerBody
FROM 
    TopUsers TU
JOIN 
    PostStats PS ON TU.TotalPosts > 0
ORDER BY 
    TU.Reputation DESC, PS.Score DESC
LIMIT 50;
