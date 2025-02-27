WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000  -- filtering users with reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.ClosedDate,
        PT.Name AS PostType 
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- posts created in the last year
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalBadges,
    UA.TotalBounty,
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.AnswerCount,
    PD.ClosedDate,
    PD.PostType
FROM 
    UserActivity UA
JOIN 
    PostDetails PD ON UA.UserId = PD.PostId
ORDER BY 
    UA.TotalPosts DESC, UA.TotalBounty DESC
LIMIT 100;  -- Limit the results for benchmarking
