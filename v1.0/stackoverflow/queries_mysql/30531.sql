
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation + 100,
        U.CreationDate,
        U.LastAccessDate,
        CTE.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputationCTE CTE ON CTE.UserId = U.Id 
    WHERE 
        CTE.Level < 10
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 50
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    U.CreationDate,
    U.LastAccessDate,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id AND PostTypeId = 1) AS QuestionCount,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id AND PostTypeId = 2) AS AnswerCount,
    P.TagName,
    P.PostCount
FROM 
    Users U
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON B.UserId = U.Id
JOIN 
    PopularTags P ON P.TagName IN (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', n.n), ',', -1)) 
        FROM 
            Posts 
        JOIN 
            (SELECT a.N + b.N * 10 AS n 
             FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
             ) n 
        WHERE 
            n.n <= 1 + LENGTH(Tags) - LENGTH(REPLACE(Tags, ',', ''))
            AND OwnerUserId = U.Id
    )
WHERE 
    U.Reputation > 1000 AND 
    (U.LastAccessDate > DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR) OR U.Location IS NOT NULL)
ORDER BY 
    U.Reputation DESC, 
    QuestionCount DESC
LIMIT 100;
