WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COALESCE(AVG(P.Score), 0) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AvgScore,
        PS.LastPostDate,
        ROW_NUMBER() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation UR
    JOIN 
        PostStats PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.TotalQuestions,
    RU.TotalAnswers,
    RU.AvgScore,
    RU.LastPostDate,
    CASE 
        WHEN RU.TotalPosts > 50 THEN 'High Contributor'
        WHEN RU.TotalPosts BETWEEN 20 AND 50 THEN 'Medium Contributor'
        ELSE 'Low Contributor'
    END AS ContributionLevel,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
        FROM Posts P 
        JOIN Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '>'))::int[])
        WHERE P.OwnerUserId = RU.UserId) AS AssociatedTags
FROM 
    RankedUsers RU
WHERE 
    RU.ReputationRank <= 10
ORDER BY 
    RU.Reputation DESC;
