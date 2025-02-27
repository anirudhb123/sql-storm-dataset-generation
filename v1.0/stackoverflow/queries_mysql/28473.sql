
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(V.BountyAmount) AS TotalBounties,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS TagsContributed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName, P.Id AS PostId 
         FROM Posts P 
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
               UNION ALL SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS T 
         ON P.Id = T.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.TotalPosts,
    U.TotalComments,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalTagWikis,
    U.TotalBounties,
    U.TagsContributed,
    (SELECT COUNT(*) FROM UserStats AS U2 WHERE U2.Reputation > U.Reputation) + 1 AS ReputationRank,
    (SELECT COUNT(*) FROM UserStats AS U3 WHERE U3.TotalPosts > U.TotalPosts) + 1 AS PostsRank
FROM 
    UserStats U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, U.TotalPosts DESC
LIMIT 10;
