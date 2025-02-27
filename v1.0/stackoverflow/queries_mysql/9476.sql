
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.Score) AS TotalScore,
        U.Reputation,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    CROSS JOIN (SELECT @row_number := 0) AS r
    WHERE 
        U.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        QuestionsCount, 
        AnswersCount, 
        TotalScore, 
        Reputation, 
        UserRank
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
)

SELECT 
    T.DisplayName, 
    T.TotalPosts, 
    T.QuestionsCount, 
    T.AnswersCount, 
    T.TotalScore, 
    T.Reputation, 
    (SELECT GROUP_CONCAT(DISTINCT TagName) FROM Tags WHERE TagName IN 
        (
            SELECT 
                TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', n.n), '>', -1)) AS TagName
            FROM 
                Posts P 
            JOIN 
                (SELECT a.N + b.N * 10 + 1 AS n 
                 FROM 
                     (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                     (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
                 ) n 
            WHERE 
                P.OwnerUserId = T.UserId
                AND n.n <= 1 + (LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '>', ''))) -- Count of delimiters
        )
    ) AS ActiveTags,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = T.UserId) AS TotalBadges
FROM 
    TopUsers T
ORDER BY 
    T.TotalScore DESC;
