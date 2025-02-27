
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(U.Reputation) AS AvgReputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostRanking AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        @row_num := @row_num + 1 AS Rank,
        P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_num := 0) r
    WHERE 
        P.PostTypeId = 1  
    ORDER BY 
        P.Score DESC
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.AvgReputation,
    U.TotalUpvotes,
    U.TotalDownvotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.Rank
FROM 
    UserStats U
JOIN 
    PostRanking P ON U.UserId = P.OwnerUserId
WHERE 
    P.Rank <= 10  
ORDER BY 
    U.TotalPosts DESC, U.AvgReputation DESC;
