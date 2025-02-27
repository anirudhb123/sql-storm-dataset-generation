
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
RankedUsers AS (
    SELECT 
        US.UserId, 
        US.DisplayName, 
        US.TotalPosts, 
        US.TotalAnswers, 
        US.TotalQuestions, 
        US.TotalScore,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        UserStatistics US, (SELECT @row_number := 0) r
    ORDER BY 
        US.TotalScore DESC
)
SELECT 
    RU.DisplayName AS User,
    RU.TotalPosts,
    RU.TotalAnswers,
    RU.TotalQuestions,
    RU.TotalScore,
    T.TagName,
    T.TagUsage,
    CASE 
        WHEN RU.TotalAnswers > 10 THEN 'Active Contributor'
        WHEN RU.TotalPosts > 20 THEN 'Frequent User'
        ELSE 'New Member'
    END AS ParticipationLevel
FROM 
    RankedUsers RU
LEFT JOIN 
    TagStatistics T ON T.TagUsage > 5
WHERE 
    RU.TotalScore > 100
ORDER BY 
    RU.TotalScore DESC,
    T.TagUsage DESC;
