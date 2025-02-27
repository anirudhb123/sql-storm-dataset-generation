
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 AND PH.PostId IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestions,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
        @rank := @rank + 1 AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    CROSS JOIN 
        (SELECT @rank := 0) r
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    ORDER BY 
        U.Reputation DESC
), 

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        ClosedQuestions,
        TotalCloseVotes
    FROM 
        RankedUsers
    WHERE 
        ReputationRank <= 10 
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.ClosedQuestions,
    TU.TotalCloseVotes,
    (SELECT COUNT(*) FROM Tags T WHERE T.Count > 500) AS PopularTagsCount,
    (SELECT GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%') 
     WHERE P.OwnerUserId = TU.UserId) AS UserTags
FROM 
    TopUsers TU
ORDER BY 
    TU.Reputation DESC;
