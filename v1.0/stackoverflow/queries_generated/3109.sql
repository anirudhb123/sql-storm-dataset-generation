WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ServerStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN PH.PostId IS NOT NULL THEN 1 END) AS TotalHistoryEntries,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    US.TotalBounties,
    US.TotalUpvotes,
    US.TotalDownvotes,
    SS.TotalPosts,
    SS.TotalQuestions,
    SS.TotalAnswers,
    SS.TotalHistoryEntries,
    SS.AvgPostScore
FROM 
    UserStats US
FULL OUTER JOIN 
    ServerStats SS ON US.UserId = SS.OwnerUserId
WHERE 
    (US.TotalUpvotes + US.TotalDownvotes) > 10 OR 
    (SS.TotalPosts > 5 AND SS.AvgPostScore > 10)
ORDER BY 
    COALESCE(US.Reputation, 0) DESC,
    COALESCE(SS.TotalPosts, 0) DESC
LIMIT 20;
