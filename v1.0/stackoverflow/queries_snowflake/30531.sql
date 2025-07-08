
WITH UserReputationCTE AS (
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
        Posts P ON POSITION(T.TagName IN P.Tags) > 0
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
            TRIM(value) 
        FROM 
            LATERAL FLATTEN(input => SPLIT((SELECT Tags FROM Posts WHERE OwnerUserId = U.Id), ','))
    )
WHERE 
    U.Reputation > 1000 AND 
    (U.LastAccessDate > TIMESTAMPADD(year, -1, '2024-10-01 12:34:56') OR U.Location IS NOT NULL)
ORDER BY 
    U.Reputation DESC, 
    QuestionCount DESC
LIMIT 100;
