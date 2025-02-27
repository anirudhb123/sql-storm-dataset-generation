
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON U.Id = C.UserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        ReputationRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5 
)
SELECT 
    TU.UserId,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    TU.ReputationRank,
    GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS PopularTags
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', n.n), ',', -1)) AS TagName
     FROM Posts P
     JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
     ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= n.n - 1) AS T ON TRUE
GROUP BY 
    TU.UserId, TU.Reputation, TU.TotalPosts, TU.TotalComments, TU.TotalUpvotes, TU.TotalDownvotes, TU.ReputationRank
ORDER BY 
    TU.Reputation DESC;
