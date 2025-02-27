
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        MAX(P.CreationDate) AS LastPostDate,
        GROUP_CONCAT(DISTINCT T.TagName) AS TagsUsed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN
        (SELECT Id, SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
                     SELECT 8 UNION ALL SELECT 9) a
               CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
                     SELECT 8 UNION ALL SELECT 9) b) n 
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
         WHERE Tags IS NOT NULL) T ON T.Id = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        LastPostDate,
        TagsUsed,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        UserEngagement, (SELECT @row_number := 0) AS rn
    ORDER BY 
        TotalPosts DESC, Reputation DESC
)

SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.TotalAnswers,
    RU.TotalBounty,
    RU.TagsUsed,
    CASE 
        WHEN RU.TotalQuestions > 0 THEN 
            (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = RU.UserId AND P.AcceptedAnswerId IS NOT NULL) 
        ELSE 
            0 
    END AS AcceptedAnswers,
    COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.UserId = RU.UserId), 0) AS TotalComments,
    CASE 
        WHEN RU.LastPostDate IS NOT NULL AND RU.LastPostDate < '2024-10-01 12:34:56' - INTERVAL 1 YEAR THEN 'Inactive for over a year'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    RankedUsers RU
WHERE 
    RU.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    RU.UserRank
LIMIT 10;
