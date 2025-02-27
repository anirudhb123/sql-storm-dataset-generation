WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes,
        RANK() OVER (ORDER BY SUM(V.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalUpvotes,
        TotalDownvotes
    FROM 
        UserStats
    WHERE 
        Rank <= 10
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalQuestions,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    AU.TotalComments,
    AU.GoldBadges,
    AU.SilverBadges,
    AU.BronzeBadges
FROM 
    TopUsers TU
JOIN 
    ActiveUsers AU ON TU.UserId = AU.UserId
ORDER BY 
    TU.Rank;
